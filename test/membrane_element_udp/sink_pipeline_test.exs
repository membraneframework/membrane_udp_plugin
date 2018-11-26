defmodule Membrane.Element.UDP.SinkPipelineTest do
  use ExUnit.Case, async: false

  alias Membrane.Pipeline

  @local_address {127, 0, 0, 1}
  @local_port_no 5050
  @destination_port_no 5005
  @values 1..100

  test "100 messages passes through pipeline" do
    data = @values |> Enum.map(&to_string(&1))

    {:ok, pipeline} =
      Pipeline.start_link(SinkPipeline, %{
        sink_local_port_no: @local_port_no,
        sink_destination_port_no: @destination_port_no,
        test_data: data
      })

    Pipeline.play(pipeline)

    {:ok, _receving_socket} =
      :gen_udp.open(@destination_port_no, [{:ip, @local_address}, :binary, {:active, true}])

    Enum.each(@values, fn elem ->
      expected_value = to_string(elem)
      assert_receive {:udp, _, @local_address, @local_port_no, ^expected_value}
    end)
  end
end
