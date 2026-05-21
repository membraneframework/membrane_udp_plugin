defmodule Membrane.UDP.CommonBehaviourTest do
  use ExUnit.Case
  use Mimic.DSL

  import Membrane.Testing.Assertions

  alias Membrane.UDP.{CommonSocketBehaviour, Socket}

  describe "CommonBehaviour" do
    test "validate_destination! accepts valid IPv4 and IPv6 with valid port" do
      assert :ok = CommonSocketBehaviour.validate_destination!({127, 0, 0, 1}, 5000)
      assert :ok = CommonSocketBehaviour.validate_destination!({0, 0, 0, 0, 0, 0, 0, 1}, 5000)
      assert :ok = CommonSocketBehaviour.validate_destination!({1, 2, 3, 4}, 1)
      assert :ok = CommonSocketBehaviour.validate_destination!({1, 2, 3, 4}, 65_535)
    end

    test "validate_destination! rejects non-tuple ip" do
      assert_raise ArgumentError, ~r/ip_address/, fn ->
        CommonSocketBehaviour.validate_destination!("127.0.0.1", 5000)
      end
    end

    test "validate_destination! rejects ip tuples of wrong size" do
      assert_raise ArgumentError, ~r/ip_address/, fn ->
        CommonSocketBehaviour.validate_destination!({1, 2, 3}, 5000)
      end
    end

    test "validate_destination! rejects out-of-range ports" do
      assert_raise ArgumentError, ~r/UDP port/, fn ->
        CommonSocketBehaviour.validate_destination!({127, 0, 0, 1}, 0)
      end

      assert_raise ArgumentError, ~r/UDP port/, fn ->
        CommonSocketBehaviour.validate_destination!({127, 0, 0, 1}, 65_536)
      end

      assert_raise ArgumentError, ~r/UDP port/, fn ->
        CommonSocketBehaviour.validate_destination!({127, 0, 0, 1}, :not_a_port)
      end
    end

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
