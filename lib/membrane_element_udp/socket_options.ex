defmodule Membrane.Element.UDP.SocketOptions do
  defstruct \
    local_port: 9000,
    local_address: :any,
    remote_address: nil,
    remote_port: nil,
    tos: 0

  @type t :: %Membrane.Element.UDP.SocketOptions{
    local_port: :inet.port_number,
    local_address: :inet.socket_address,
    remote_port: :inet.port_number,
    remote_address: :inet.socket_address,
    tos: non_neg_integer,
  }
end
