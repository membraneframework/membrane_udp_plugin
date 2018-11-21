defmodule Membrane.Element.UDP.CommonPort do
  @moduledoc false

  @spec open(map()) :: {:ok, :gen_udp.socket()} | {{:error, {:open, :inet.posix()}}, map()}
  def open(
        %{
          local_address: address,
          local_port_no: port_no
        } = state
      ) do
    case :gen_udp.open(port_no, [{:ip, address}, :binary, {:active, true}]) do
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
          iodata(),
          map()
        ) :: :ok | {:error, :not_owner | :inet.posix()}
  def send(
        payload,
        %{
          destination_address: destination_address,
          destination_port_no: destination_port_no,
          socket_handle: port
        } = state
      ) do
    case :gen_udp.send(port, destination_address, destination_port_no, payload) do
      :ok ->
        {{:ok, demand: :input}, state}

      {:error, _reason} = result ->
        {result, state}
    end
  end
end
