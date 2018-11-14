defmodule Membrane.Element.UDP.CommonPort do
  @spec open(String.t(), non_neg_integer(), map()) ::
          {:ok, :gen_udp.socket()} | {{:error, {:open, :inet.posix()}}, map()}
  def open(address, port, state) do
    case :gen_udp.open(port, [{:ip, address}, :binary, {:active, true}]) do
      {:ok, port} -> {:ok, %{state | open_port: port}}
      {:error, reason} -> {{:error, {:open, reason}}, state}
    end
  end

  @spec close(port()) :: :ok
  def close(port) when is_port(port) do
    :gen_udp.close(port)
  end

  @spec send(:gen_udp.socket(), any(), :inet.socket_address(), non_neg_integer) ::
          :ok | {:error, :not_owner | :inet.posix()}
  def send(port, data, target_ip, target_port) do
    :gen_udp.send(port, target_ip, target_port, data)
  end
end
