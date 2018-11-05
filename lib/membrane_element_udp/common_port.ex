defmodule Membrane.Element.UDP.CommonPort do
  @timeout 30 * 60 * 1000

  def open(address, port) do
    :gen_udp.open(port, [{:ip, address}, :binary, {:active, true}])
  end

  def close(port) when is_port(port) do
    :gen_udp.close(port)
  end

  def receive_batch(port) do
    :gen_udp.recv(port, 0, @timeout)
  end
end
