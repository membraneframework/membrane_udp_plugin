defmodule Membrane.Element.UDPSocket.SocketOptions do
  defstruct \
    port: nil,
    remote_address: nil,
    remote_port: nil

  @type t :: %Membrane.Element.UDPSocket.SocketOptions{
    port: non_neg_integer,
    remote_port: :inet.port_number,
    remote_address: :inet.socket_address
  }
end