defmodule Membrane.Element.UDP.CommonPort do
  @moduledoc false

  @spec open(String.t(), non_neg_integer(), map()) ::
          {:ok, :gen_udp.socket()} | {{:error, {:open, :inet.posix()}}, map()}
  def open(address, port, state) do
    case :gen_udp.open(port, [{:ip, address}, :binary, {:active, true}]) do
      {:ok, port} -> {:ok, %{state | socket_handle: port}}
      {:error, reason} -> {{:error, {:open, reason}}, state}
    end
  end

  @spec close(state :: map()) :: {:ok, map()}
  def close(%{socket_handle: socket_handle} = state) when is_port(socket_handle) do
    :gen_udp.close(socket_handle)
    {:ok, %{state | socket_handle: nil}}
  end

  @spec send(
          :gen_udp.socket(),
          iodata(),
          :inet.socket_address(),
          target_port_no :: non_neg_integer
        ) :: :ok | {:error, :not_owner | :inet.posix()}
  def send(port, data, target_ip, target_port_no) do
    :gen_udp.send(port, target_ip, target_port_no, data)
  end
end
