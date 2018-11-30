defmodule Membrane.Element.UDP.SinkPipelineTest do
  use ExUnit.Case, async: false

  import SocketSetup

  alias Membrane.Element.UDP.SocketFactory
  alias Membrane.Pipeline

  @local_address SocketFactory.local_address()
  @local_port_no 5051
  @destination_port_no 5015
  @values 1..100

  def setup_state(_ctx) do
    open_local_socket = SocketFactory.local_socket(@destination_port_no)

    %{state: %{local_socket: open_local_socket}}
  end

  setup [:setup_state, :setup_socket_from_state]

  @tag open_socket_from_state: [:local_socket]
  test "100 messages passes through pipeline" do
    data = @values |> Enum.map(&to_string(&1))

    {:ok, pipeline} =
      SinkPipeline.start_link(%{
        sink_local_port_no: @local_port_no,
        sink_destination_port_no: @destination_port_no,
        test_data: data
      })

    Pipeline.play(pipeline)

    Enum.each(@values, fn elem ->
      expected_value = to_string(elem)
      assert_receive {:udp, _, @local_address, @local_port_no, ^expected_value}
    end)
  end
end
