defmodule Membrane.UDP.CommonSocketBehaviour do
  @moduledoc false

  import Mockery.Macro

  alias Membrane.Element
  alias Membrane.Element.Base
  alias Membrane.Element.CallbackContext.{Setup, TerminateRequest}
  alias Membrane.UDP.Socket

  @spec handle_setup(
          context :: Setup.t(),
          state :: Element.state_t()
        ) :: Base.callback_return_t()
  def handle_setup(_context, %{local_socket: local_socket} = state) do
    case mockable(Socket).open(local_socket) do
      {:ok, socket} ->
        notification = {:connection_info, socket.ip_address, socket.port_no}
        {[notify_parent: notification], %{state | local_socket: socket}}

      {:error, reason} ->
        raise "Error: #{inspect(reason)}"
    end
  end

  @spec handle_terminate_request(
          context :: TerminateRequest.t(),
          state :: Element.state_t()
        ) :: Base.callback_return_t()
  def handle_terminate_request(_context, %{local_socket: local_socket} = state) do
    updated_socket = mockable(Socket).close(local_socket)

    {[terminate: :normal], %{state | local_socket: updated_socket}}
  end
end
