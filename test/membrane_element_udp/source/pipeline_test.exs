defmodule Membrane.Element.UDP.SourcePipelineTest do
  use ExUnit.Case, async: false

  alias Membrane.Testing
  alias Membrane.Pipeline
  alias Membrane.Element.UDP.{SocketFactory, Source}

  import Testing.Pipeline.Assertions

  @local_address {127, 0, 0, 1}
  @local_port_no 5050
  @destination_port_no 5051
  @values 1..100

  test "100 messages passes through pipeline" do
    data = @values |> Enum.map(&to_string(&1))

    {:ok, pipeline} =
      Pipeline.start_link(Testing.Pipeline, %Testing.Pipeline.Options{
        elements: [
          udp_source: %Source{
            local_address: SocketFactory.local_address(),
            local_port_no: @destination_port_no
          },
          test_sink: %Testing.Sink{target: self()}
        ],
        test_process: self(),
        monitored_callbacks: [:handle_prepared_to_playing]
      })

    Pipeline.play(pipeline)

    assert_receive_message(:handle_prepared_to_playing)

    Enum.map(data, fn elem ->
      udp_like_message = {:udp, nil, @local_address, @local_port_no, elem}
      Testing.Pipeline.message_child(pipeline, :udp_source, udp_like_message)
    end)

    Enum.each(data, fn elem ->
      expected_value = to_string(elem)

      assert_receive %Membrane.Buffer{
                       metadata: %{
                         udp_source_address: @local_address,
                         udp_source_port: @local_port_no
                       },
                       payload: ^expected_value
                     },
                     2000
    end)
  end
end
