defmodule Membrane.Element.UDP.CommonBehaviourTest do
  use ExUnit.Case
  use Mockery

  alias Membrane.Element.UDP.{CommonSocketBehaviour, Socket, SocketFactory}

  describe "CommonBehaviour" do
    test "opens socket when transitioning from stopped to prepared" do
      socket = SocketFactory.local_socket(123)

      mock(Socket, [open: 1], fn socket ->
        {:ok, %Socket{socket | socket_handle: self()}}
      end)

      state = %{local_socket: socket}

      assert {:ok, %{local_socket: result_socket}} =
               CommonSocketBehaviour.handle_stopped_to_prepared(nil, state)

      assert result_socket.socket_handle == self()
      assert_called(Socket, :open)
    end
  end

  test "closes socket when transitioning from prepared to stopped and sets socket_handle of socket struct in state to nil" do
    socket = %Socket{port_no: 123, ip_address: {127, 0, 0, 1}, socket_handle: :i_am_socket}
    mock(Socket, [close: 1], %Socket{socket | socket_handle: nil})

    {:ok, %{local_socket: %Socket{socket_handle: nil}}} =
      CommonSocketBehaviour.handle_prepared_to_stopped(nil, %{local_socket: socket})

    assert_called(Socket, close: 1)
  end
end
