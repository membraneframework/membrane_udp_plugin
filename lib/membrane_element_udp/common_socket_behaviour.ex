defmodule Membrane.Element.UDP.CommonSocketBehaviour do
  @moduledoc false
  import Mockery.Macro
  alias Membrane.Element.UDP.Socket

  def handle_stopped_to_prepared(_ctx, %{local_socket: local_socket} = state) do
    case mockable(Socket).open(local_socket) do
      {:ok, socket} -> {:ok, %{state | local_socket: socket}}
      {:error, reason} -> {{:error, reason}, state}
    end
  end

  def handle_prepared_to_stopped(_ctx, state) do
    new_state = mockable(Socket).close(state)
    {:ok, %{state: new_state}}
  end
end
