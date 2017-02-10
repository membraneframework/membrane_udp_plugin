defmodule Membrane.Element.UDPSocket.Socket do
  use Membrane.Element.Base.Filter
  alias Membrane.Element.UDPSocket.SocketOptions
  
  def_known_source_pads %{
    :sink => {:always, [:any]}
  }

  def_known_sink_pads %{
    :sink => {:always, [:any]}
  }


  @doc false
  def handle_init(%SocketOptions{} = options) do
    {:ok, Map.put_new(options, :socket, nil)}
  end


  @doc false
  def handle_prepare(_prev_state, %{port: port} = state) do
    {:ok, socket} = :gen_udp.open(port, [{:tos, 0}, :binary])
    :gen_udp.controlling_process(socket, self())
    {:ok, %{state | socket: socket}}
  end


  @doc false
  def handle_buffer(_caps, data, %{socket: socket, remote_address: remote_address, remote_port: remote_port} = state) do
    if remote_address != nil and remote_port != nil do
        :gen_udp.send(socket, remote_address, remote_port, data)
    end
    {:ok, state}
  end


  @doc false
  def handle_other(message, %{remote_port: remote_port, remote_address: remote_address} = state) do 

    state = case {remote_address, remote_port} do
      
      {nil, nil} ->
        case message do
          {:udp, _port, packet_address, packet_port, _data} ->
            %{state | remote_address: packet_address, remote_port: packet_port}
          _ -> state
        end

      _ ->
        state
    end

    %{remote_address: remote_address, remote_port: remote_port} = state

    case message do
      {:udp, _port, ^remote_address, ^remote_port, data} -> 
        {:ok, [{:send, {:source, data}}], state}
      _ ->
        {:error, :invalid_message, state}
    end

  end

end