defmodule Membrane.Element.UDP.SocketOptions do
  defstruct \
    port: 9000,
    remote_address: nil,
    remote_port: nil,
    tos: 0

  @type t :: %Membrane.Element.UDP.SocketOptions{
    port: non_neg_integer,
    remote_port: :inet.port_number,
    remote_address: :inet.socket_address,
    tos: non_neg_integer,
  }
end
