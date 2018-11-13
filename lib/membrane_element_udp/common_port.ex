defmodule Membrane.Element.UDP.CommonPort do
  def open(address, port) do
    :gen_udp.open(port, [{:ip, address}, :binary, {:active, true}])
  end

  def close(port) when is_port(port) do
    :gen_udp.close(port)
  end
end
