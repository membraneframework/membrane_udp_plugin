defmodule SocketSetup do
  @moduledoc false
  import ExUnit.Callbacks, only: [on_exit: 1]

  alias Membrane.Element.UDP.Socket

  def setup_socket_from_state(%{open_socket_from_state: requested, state: state}) do
    new_state =
      Enum.reduce(requested, state, fn socket_name, acc ->
        Map.update!(acc, socket_name, fn socket ->
          setup_socket(socket)
        end)
      end)

    %{state: new_state}
  end

  def setup_socket(socket) do
    {:ok, opened_local_socket} = Socket.open(socket)
    on_exit(fn -> Socket.close(opened_local_socket) end)
    opened_local_socket
  end
end
