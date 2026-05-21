defmodule Membrane.UDP.SinkIntegrationTest do
  use ExUnit.Case, async: false

  import SocketSetup

  alias Membrane.Buffer
  alias Membrane.UDP.{Endpoint, Sink, Socket}

  @destination_port_no 5001
  @local_port_no 5000
  @local_address {127, 0, 0, 1}

  defp setup_state(_ctx) do
    dst_socket = %Socket{port_no: @destination_port_no, ip_address: @local_address}
    local_socket = %Socket{port_no: @local_port_no, ip_address: @local_address}

    %{state: %{dst_socket: dst_socket, local_socket: local_socket}}
  end

  setup [:setup_state, :setup_socket_from_state]

  for module <- [Endpoint, Sink] do
    @tag open_socket_from_state: [:dst_socket, :local_socket]
    test "Sends udp packet through #{inspect(module)}", %{state: state} do
      payload = "A lot of laughs"

      unquote(module).handle_buffer(:input, %Buffer{payload: payload}, nil, state)

      assert_receive {:udp, _, @local_address, @local_port_no, ^payload}
    end

    @tag open_socket_from_state: [:dst_socket, :local_socket]
    test ":set_destination redirects packets to the new port via #{inspect(module)}",
         %{state: state} do
      alt_port = @destination_port_no + 100

      alt_socket =
        SocketSetup.setup_socket(%Socket{port_no: alt_port, ip_address: @local_address})

      alt_handle = alt_socket.socket_handle
      dst_handle = state.dst_socket.socket_handle

      unquote(module).handle_buffer(:input, %Buffer{payload: "before"}, nil, state)
      assert_receive {:udp, ^dst_handle, @local_address, @local_port_no, "before"}

      {[], new_state} =
        unquote(module).handle_parent_notification(
          {:set_destination, @local_address, alt_port},
          nil,
          state
        )

      unquote(module).handle_buffer(:input, %Buffer{payload: "after"}, nil, new_state)

      assert_receive {:udp, ^alt_handle, @local_address, @local_port_no, "after"}
      refute_receive {:udp, ^dst_handle, _, _, "after"}, 100
    end
  end
end
