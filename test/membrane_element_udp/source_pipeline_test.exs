defmodule Membrane.Element.UDP.SourcePipelineTest do
  use ExUnit.Case, async: false
  import SocketSetup

  alias Membrane.Element.UDP.Socket
  alias Membrane.Pipeline

  @local_address {127, 0, 0, 1}
  @local_port_no 5050
  @destination_port_no 5005
  @values 1..100

  def setup_state(_ctx) do
    local_socket = %Socket{ip_address: @local_address, port_no: @local_port_no}

    %{state: %{local_socket: local_socket}}
  end

  setup [:setup_state, :setup_socket_from_state]

  @tag open_socket_from_state: [:local_socket]
  test "100 messages passes through pipeline", %{state: %{local_socket: local_socket}} do
    data = @values |> Enum.map(&to_string(&1))

    {:ok, pipeline} =
      Pipeline.start_link(SourcePipeline, %{
        port_no: @destination_port_no,
        test_process: self()
      })

    Pipeline.play(pipeline)
    assert_receive {SourcePipeline, :playing}

    Enum.each(data, fn elem ->
      Socket.send(
        %Socket{ip_address: @local_address, port_no: @destination_port_no},
        local_socket,
        elem
      )
    end)

    Enum.each(data, fn elem ->
      expected_value = to_string(elem)

      assert_receive {:udp_source,
                      %Membrane.Buffer{
                        metadata: %{
                          udp_source_address: @local_address,
                          udp_source_port: @local_port_no
                        },
                        payload: ^expected_value
                      }}
    end)
  end
end
