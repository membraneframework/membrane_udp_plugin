defmodule Membrane.UDP.SocketFactory do
  @moduledoc false

  alias Membrane.UDP.Socket

  @local {127, 0, 0, 1}

  @spec local_socket(port :: :inet.port_number()) :: Socket.t()
  def local_socket(port),
    do: %Socket{
      port_no: port,
      ip_address: @local
    }

  @spec local_address() :: :inet.socket_address()
  def local_address, do: @local
end
