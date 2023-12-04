defmodule Membrane.UDP.IntegrationTest do
  use ExUnit.Case, async: false

  import Membrane.Testing.Assertions
  import Membrane.ChildrenSpec

  alias Membrane.{Buffer, Testing}
  alias Membrane.Testing.Pipeline
  alias Membrane.UDP

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
