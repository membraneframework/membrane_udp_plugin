defmodule Membrane.Element.UDP.CommonPort do
  def open(address, port) do
    :gen_udp.open(port, [{:ip, address}, :binary, {:active, true}])
  end

  def close(port) when is_port(port) do
    :gen_udp.close(port)
  end

  def send(port, data, target_ip, target_port) do
    :gen_udp.send(port, target_ip, target_port, data)
  end
end
