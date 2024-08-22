defmodule Membrane.UDP.CommonSocketBehaviour do
  @moduledoc false

  import Mockery.Macro

  alias Membrane.Element
  alias Membrane.Element.CallbackContext
  alias Membrane.UDP.Socket

  @spec handle_setup(
          context :: CallbackContext.t(),
          state :: Element.state()
        ) ::
          {[Membrane.Element.Action.common_actions() | Membrane.Element.Action.setup()],
           Membrane.Element.state()}
  def handle_setup(ctx, %{local_socket: %Socket{socket_handle: nil} = local_socket} = state) do
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

  def handle_setup(_ctx, %{local_socket: %Socket{socket_handle: handle} = local_socket} = state) do
    {:ok, {socket_address, socket_port}} = :inet.sockname(handle)

    cond do
      local_socket.ip_address not in [socket_address, :any] ->
        raise "Local address passed in options not matching the one of the passed socket."

      local_socket.port_no not in [socket_port, 0] ->
        raise "Local port passed in options not matching the one of the passed socket."

      true ->
        :ok
    end

    {[], %{state | local_socket: local_socket}}
  end

  defp close_socket(%Socket{} = local_socket) do
    mockable(Socket).close(local_socket)
  end
end
