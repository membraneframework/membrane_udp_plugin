defmodule Membrane.Element.UDP.CommonSocketBehaviour do
  @moduledoc false
  alias Membrane.Element
  alias Membrane.Element.Base.Mixin.CommonBehaviour
  alias Membrane.Element.UDP.Socket
  alias Membrane.Element.CallbackContext.PlaybackChange

  @socket Socket

  @spec handle_stopped_to_prepared(
          context :: PlaybackChange.t(),
          state :: Element.state_t()
        ) :: CommonBehaviour.callback_return_t()
  def handle_stopped_to_prepared(_context, %{local_socket: local_socket} = state) do
    case @socket.open(local_socket) do
      {:ok, socket} -> {:ok, %{state | local_socket: socket}}
      {:error, reason} -> {{:error, reason}, state}
    end
  end

  @spec handle_prepared_to_stopped(
          context :: PlaybackChange.t(),
          state :: Element.state_t()
        ) :: CommonBehaviour.callback_return_t()
  def handle_prepared_to_stopped(_context, %{local_socket: local_socket} = state) do
    @socket.close(local_socket)
    {:ok, %{state | local_socket: nil}}
  end
end
