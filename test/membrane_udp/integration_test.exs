defmodule Membrane.UDP.IntegrationTest do
  use ExUnit.Case, async: false

  import Membrane.Testing.Assertions
  import Membrane.ChildrenSpec

  alias Membrane.{Buffer, Testing}
  alias Membrane.Testing.Pipeline
  alias Membrane.UDP

  defmodule PushSource do
    @moduledoc false
    use Membrane.Source

    def_output_pad :output, accepted_format: _any, flow_control: :push

    @impl true
    def handle_init(_ctx, _opts), do: {[], %{}}

    @impl true
    def handle_playing(_ctx, state) do
      {[stream_format: {:output, %Membrane.RemoteStream{type: :packetized}}], state}
    end

    @impl true
    def handle_parent_notification({:push, payload}, _ctx, state) do
      {[buffer: {:output, %Membrane.Buffer{payload: payload}}], state}
    end
  end

  @target_port 5000
  @server_port 6789
  @localhostv4 {127, 0, 0, 1}

  @payload_frames 50

  test "send and receive using 2 pipelines" do
    payload = 1..@payload_frames |> Enum.map(&inspect/1)

    receiver =
      Pipeline.start_link_supervised!(
        spec: [
          child(:source, %UDP.Source{local_port_no: @target_port, local_address: @localhostv4})
          |> child(:sink, %Testing.Sink{})
        ]
      )

    assert_pipeline_notified(receiver, :source, {:connection_info, @localhostv4, @target_port})

    sender =
      Pipeline.start_link_supervised!(
        spec: [
          child(:source, %Testing.Source{output: payload})
          |> child(:sink, %UDP.Sink{
            destination_port_no: @target_port,
            destination_address: @localhostv4
          })
        ]
      )

    assert_pipeline_notified(
      sender,
      :sink,
      {:connection_info, {0, 0, 0, 0}, _some_ephemeral_port}
    )

    assert_end_of_stream(sender, :sink)

    1..@payload_frames
    |> Enum.each(fn x ->
      payload = inspect(x)
      assert_sink_buffer(receiver, :sink, %Buffer{payload: ^payload})
    end)

    Pipeline.terminate(sender)
    Pipeline.terminate(receiver)
  end

  test "send and receive using 1 pipeline with endpoint" do
    payload = 1..@payload_frames |> Enum.map(&inspect/1)

    pipeline =
      Pipeline.start_link_supervised!(
        spec: [
          child(:endpoint, %UDP.Endpoint{
            local_port_no: @target_port,
            local_address: @localhostv4,
            destination_port_no: @target_port,
            destination_address: @localhostv4
          })
          |> child(:sink, %Testing.Sink{}),
          child(:source, %Testing.Source{output: payload})
          |> get_child(:endpoint)
        ]
      )

    assert_pipeline_notified(pipeline, :endpoint, {:connection_info, @localhostv4, @target_port})

    assert_end_of_stream(pipeline, :endpoint)

    1..@payload_frames
    |> Enum.each(fn x ->
      payload = inspect(x)
      assert_sink_buffer(pipeline, :sink, %Buffer{payload: ^payload})
    end)

    Pipeline.terminate(pipeline)
  end

  for {element, base_port} <- [{UDP.Endpoint, 6100}, {UDP.Sink, 6200}] do
    test ":set_destination at runtime redirects packets through #{inspect(element)}" do
      initial_port = unquote(base_port) + 1
      new_port = unquote(base_port) + 2

      {:ok, probe_initial} =
        :gen_udp.open(initial_port, [:binary, ip: @localhostv4, active: true])

      {:ok, probe_new} =
        :gen_udp.open(new_port, [:binary, ip: @localhostv4, active: true])

      on_exit(fn ->
        :gen_udp.close(probe_initial)
        :gen_udp.close(probe_new)
      end)

      udp_child =
        struct!(unquote(element), %{
          local_port_no: 0,
          local_address: @localhostv4,
          destination_port_no: initial_port,
          destination_address: @localhostv4
        })

      base_link = child(:source, PushSource) |> child(:udp, udp_child)

      spec =
        if unquote(element) == UDP.Endpoint do
          base_link |> child(:fake_sink, %Membrane.Debug.Sink{})
        else
          base_link
        end

      pipeline = Pipeline.start_link_supervised!(spec: spec)

      assert_pipeline_notified(pipeline, :udp, {:connection_info, _addr, _port})

      Pipeline.execute_actions(pipeline, notify_child: {:source, {:push, "first"}})
      assert_receive {:udp, ^probe_initial, @localhostv4, _from_port, "first"}, 2000

      Pipeline.execute_actions(pipeline,
        notify_child: {:udp, {:set_destination, @localhostv4, new_port}}
      )

      Pipeline.execute_actions(pipeline, notify_child: {:source, {:push, "second"}})
      assert_receive {:udp, ^probe_new, @localhostv4, _from_port, "second"}, 2000
      refute_receive {:udp, ^probe_initial, _, _, "second"}, 100

      Pipeline.terminate(pipeline)
    end
  end

  test "NAT pierce datagram comes through" do
    {:ok, server_sock} =
      UDP.Socket.open(%UDP.Socket{port_no: @server_port, ip_address: @localhostv4})

    client =
      Pipeline.start_link_supervised!(
        spec: [
          child(:source, %UDP.Source{
            local_port_no: @target_port,
            local_address: @localhostv4,
            pierce_nat_ctx: %{
              address: @localhostv4,
              port: @server_port
            }
          })
          |> child(:sink, %Testing.Sink{})
        ]
      )

    assert_pipeline_notified(client, :source, {:connection_info, @localhostv4, @target_port})

    handle = server_sock.socket_handle
    assert_receive({:udp, ^handle, @localhostv4, @target_port, <<>>}, 20_000)
  end
end
