defmodule Membrane.UDP.SourcePipelineTest do
  use ExUnit.Case, async: false

  import Membrane.Testing.Assertions

  alias Membrane.UDP.{SocketFactory, Source}
  alias Membrane.Testing.{Pipeline, Sink}

  @local_address {127, 0, 0, 1}
  @local_port_no 5052
  @destination_port_no 5053
  @values 1..100

  test "100 messages passes through pipeline" do
    data = @values |> Enum.map(&to_string(&1))

    assert {:ok, pipeline} =
             Pipeline.start_link(%Pipeline.Options{
               elements: [
                 udp_source: %Source{
                   local_address: SocketFactory.local_address(),
                   local_port_no: @destination_port_no
                 },
                 sink: %Sink{}
               ],
               test_process: self()
             })

    assert_pipeline_playback_changed(pipeline, :prepared, :playing)

    Enum.map(data, fn elem ->
      udp_like_message = {:udp, nil, @local_address, @local_port_no, elem}
      Pipeline.message_child(pipeline, :udp_source, udp_like_message)
    end)

    Enum.each(data, fn elem ->
      expected_value = to_string(elem)

      assert_sink_buffer(
        pipeline,
        :sink,
        %Membrane.Buffer{
          metadata: %{
            udp_source_address: @local_address,
            udp_source_port: @local_port_no
          },
          payload: ^expected_value
        },
        2000
      )
    end)

    Pipeline.terminate(pipeline, blocking?: true)
  end
end
