defmodule Membrane.UDP.SinkUnitTest do
  use ExUnit.Case
  use Mimic.DSL

  alias Membrane.Buffer
  alias Membrane.UDP.{Endpoint, Sink, Socket}

  @local_address {127, 0, 0, 1}

  for module <- [Endpoint, Sink] do
    describe "#{inspect(module)} element" do
      test "handle_buffer/4 calls send and demands more data" do
        payload_data = "binary data"
        local_socket = %Socket{port_no: 1234, ip_address: @local_address}
        dst_socket = %Socket{port_no: 4321, ip_address: @local_address}
        expect(Socket.send(^dst_socket, ^local_socket, ^payload_data), do: :ok)

        state = %{
          local_socket: local_socket,
          dst_socket: dst_socket
        }

        assert unquote(module).handle_buffer(:input, %Buffer{payload: payload_data}, nil, state) ==
                 {[], state}
      end

      test "handle_parent_notification/3 :set_destination updates dst_socket" do
        local_socket = %Socket{port_no: 1234, ip_address: @local_address}
        dst_socket = %Socket{port_no: 4321, ip_address: @local_address}
        state = %{local_socket: local_socket, dst_socket: dst_socket}

        new_ip = {1, 2, 3, 4}
        new_port = 9000

        assert {[], new_state} =
                 unquote(module).handle_parent_notification(
                   {:set_destination, new_ip, new_port},
                   nil,
                   state
                 )

        assert new_state.dst_socket.ip_address == new_ip
        assert new_state.dst_socket.port_no == new_port
        assert new_state.local_socket == local_socket
      end

      test "handle_parent_notification/3 :set_destination raises on bad input" do
        local_socket = %Socket{port_no: 1234, ip_address: @local_address}
        dst_socket = %Socket{port_no: 4321, ip_address: @local_address}
        state = %{local_socket: local_socket, dst_socket: dst_socket}

        assert_raise ArgumentError, fn ->
          unquote(module).handle_parent_notification(
            {:set_destination, "1.2.3.4", 9000},
            nil,
            state
          )
        end

        assert_raise ArgumentError, fn ->
          unquote(module).handle_parent_notification(
            {:set_destination, {1, 2, 3, 4}, 70_000},
            nil,
            state
          )
        end
      end
    end
  end
end
