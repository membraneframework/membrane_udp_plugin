defmodule Membrane.UDP.CommonBehaviourTest do
  use ExUnit.Case
  use Mockery

  import Membrane.Testing.Assertions

  alias Membrane.UDP.{CommonSocketBehaviour, Socket, SocketFactory}

  describe "CommonBehaviour" do
    test "opens and close socket when transitioning through states" do
      # socket up
      socket = SocketFactory.local_socket(123)
      guard = Membrane.Testing.MockResourceGuard.start_link_supervised!()

      mock(Socket, [open: 1], fn socket ->
        {:ok, %Socket{socket | socket_handle: self()}}
      end)

      ctx = %{resource_guard: guard}
      state = %{local_socket: socket}

      assert {_actions, %{local_socket: result_socket}} =
               CommonSocketBehaviour.handle_setup(ctx, state)

      assert_resource_guard_register(guard, close_socket, :udp_guard)

      assert result_socket.socket_handle == self()
      assert_called(Socket, :open)

      # socket down
      mock(Socket, [close: 1], %Socket{socket | socket_handle: nil})
      close_socket.()
      assert_called(Socket, close: 1)
    end
  end
end
