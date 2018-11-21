defmodule Membrane.Element.UDP.SourcePipelineTest do
  use ExUnit.Case

  alias Membrane.Pipeline

  @local_address {127, 0, 0, 1}
  @local_port_no 5050
  @destination_port_no 5005
  @values 1..1000

  test "Dozen of messages passes through pipeline" do
    data = @values |> Enum.map(&to_string(&1))

    {:ok, pipeline} =
      Pipeline.start_link(SourcePipeline, %{
        port_no: @destination_port_no,
        test_process: self()
      })

    {:ok, sending_socket} =
      :gen_udp.open(@local_port_no, [{:ip, @local_address}, :binary, {:active, true}])

    Enum.each(data, fn elem ->
      :gen_udp.send(sending_socket, @local_address, @local_port_no, to_string(elem))
    end)

    Pipeline.play(pipeline)

    Enum.each(data, fn elem ->
      expected_value = to_string(elem)
      assert_receive {:udp, _, @local_address, @local_port_no, ^expected_value}
    end)
  end
end
