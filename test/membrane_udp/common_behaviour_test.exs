defmodule Membrane.UDP.CommonBehaviourTest do
  use ExUnit.Case
  use Mimic.DSL

  import Membrane.Testing.Assertions

  alias Membrane.UDP.{CommonSocketBehaviour, Socket}

  describe "CommonBehaviour" do
    test "opens and close socket when transitioning through states" do
      # socket up
      socket = %Socket{port_no: 123, ip_address: {127, 0, 0, 1}}
      guard = Membrane.Testing.MockResourceGuard.start_link_supervised!()

      expect(Socket.open(socket), do: {:ok, %{socket | socket_handle: self()}})

      ctx = %{resource_guard: guard}
      state = %{local_socket: socket}

      assert {_actions, %{local_socket: result_socket}} =
               CommonSocketBehaviour.handle_setup(ctx, state)

      assert_resource_guard_register(guard, close_socket, :udp_guard)

      assert result_socket.socket_handle == self()

      self_pid = self()

      expect(Socket.close(%{socket_handle: ^self_pid} = socket),
        do: %{socket | socket_handle: nil}
      )

      close_socket.()
    end
  end
end
