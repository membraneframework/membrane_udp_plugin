defmodule Membrane.Element.UDP.CommonSocketBehaviour do
  @moduledoc false

  import Mockery.Macro

  alias Membrane.Element
  alias Membrane.Element.Base
  alias Membrane.Element.CallbackContext.PlaybackChange
  alias Membrane.Element.UDP.Socket

  @spec handle_stopped_to_prepared(
          context :: PlaybackChange.t(),
          state :: Element.state_t()
        ) :: Base.callback_return_t()
  def handle_stopped_to_prepared(_context, %{local_socket: local_socket} = state) do
    case mockable(Socket).open(local_socket) do
      {:ok, socket} -> {:ok, %{state | local_socket: socket}}
      {:error, reason} -> {{:error, reason}, state}
    end
  end

  @spec handle_prepared_to_stopped(
          context :: PlaybackChange.t(),
          state :: Element.state_t()
        ) :: Base.callback_return_t()
  def handle_prepared_to_stopped(_context, %{local_socket: local_socket} = state) do
    updated_socket = mockable(Socket).close(local_socket)
    {:ok, %{state | local_socket: updated_socket}}
  end
end
