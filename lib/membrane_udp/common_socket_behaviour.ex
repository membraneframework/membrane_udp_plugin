defmodule Membrane.UDP.CommonSocketBehaviour do
  @moduledoc false

  import Mockery.Macro

  alias Membrane.Element
  alias Membrane.Element.Base
  alias Membrane.Element.CallbackContext
  alias Membrane.UDP.Socket

  @spec handle_setup(
          context :: CallbackContext.t(),
          state :: Element.state()
        ) :: Base.callback_return()
  def handle_setup(ctx, %{local_socket: %Socket{} = local_socket} = state) do
    case mockable(Socket).open(local_socket) do
      {:ok, socket} ->
        notification = {:connection_info, socket.ip_address, socket.port_no}

        Membrane.ResourceGuard.register(
          ctx.resource_guard,
          fn -> close_socket(socket) end,
          tag: :udp_guard
        )

        {[notify_parent: notification], %{state | local_socket: socket}}

      {:error, reason} ->
        raise "Error opening UDP socket, reason: #{inspect(reason)}"
    end
  end

  defp close_socket(%Socket{} = local_socket) do
    mockable(Socket).close(local_socket)
  end
end
