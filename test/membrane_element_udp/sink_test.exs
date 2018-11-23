defmodule Membrane.Element.UDP.SinkTest do
  use ExUnit.Case, async: false
  use Mockery

  alias Membrane.Element.UDP.Sink
  alias Membrane.Element.UDP.Socket
  alias Membrane.Buffer

  import SocketSetup

  @local_address {127, 0, 0, 1}
  @destination_port_no 5001
  @local_port_no 5000

  def setup_state(ctx) do
    open_local_socket = %Socket{ip_address: @local_address, port_no: @local_port_no}
    dst_socket = %Socket{ip_address: @local_address, port_no: @destination_port_no}

    Map.put(ctx, :state, %{
      local_socket: open_local_socket,
      dst_socket: dst_socket
    })
  end

  setup ctx do
    ctx
    |> setup_state()
    |> setup_socket_from_state()
  end

  @tag open_socket_from_state: [:dst_socket, :local_socket]
  test "Sends udp packet", %{state: state} do
    payload = "A lot of laughs"
    Sink.handle_write(:input, %Buffer{payload: payload}, nil, state)

    assert_receive {:udp, _, {127, 0, 0, 1}, 5000, ^payload}
  end
end
