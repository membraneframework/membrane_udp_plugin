defmodule Membrane.UDP.SinkPipelineTest do
  use ExUnit.Case, async: false

  import SocketSetup
  import Membrane.ChildrenSpec

  alias Membrane.UDP.{Sink, Socket}
  alias Membrane.Testing.{Pipeline, Source}

  @local_address {127, 0, 0, 1}
  @local_port_no 5051
  @destination_port_no 5015
  @values 1..100

  defp setup_state(_ctx) do
    open_local_socket = %Socket{port_no: @destination_port_no, ip_address: @local_address}

    %{state: %{local_socket: open_local_socket}}
  end

  setup [:setup_state, :setup_socket_from_state]

  @tag open_socket_from_state: [:local_socket]
  test "100 messages passes through pipeline" do
    data = @values |> Enum.map(&to_string(&1))

    assert pipeline =
             Pipeline.start_link_supervised!(
               spec: [
                 child(:test_source, %Source{output: data})
                 |> child(:udp_sink, %Sink{
                   destination_address: @local_address,
                   destination_port_no: @destination_port_no,
                   local_address: @local_address,
                   local_port_no: @local_port_no
                 })
               ]
             )

    Enum.each(@values, fn elem ->
      expected_value = to_string(elem)
      assert_receive {:udp, _, @local_address, @local_port_no, ^expected_value}, 1000
    end)

    Pipeline.terminate(pipeline)
  end
end
