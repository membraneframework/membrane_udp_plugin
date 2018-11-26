defmodule Membrane.Element.UDP.CommonSocketBehaviour do
  @moduledoc false
  import Mockery.Macro
  alias Membrane.Element.UDP.Socket

  def handle_stopped_to_prepared(_context, %{local_socket: local_socket} = state) do
    case mockable(Socket).open(local_socket) do
      {:ok, socket} -> {:ok, %{state | local_socket: socket}}
      {:error, reason} -> {{:error, reason}, state}
    end
  end

  def handle_prepared_to_stopped(_context, state) do
    mockable(Socket).close(state)
    {:ok, %{state: nil}}
  end
end
