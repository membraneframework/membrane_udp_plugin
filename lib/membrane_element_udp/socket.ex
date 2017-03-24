defmodule Membrane.Element.UDP.Socket do
  use Membrane.Element.Base.Filter
  alias Membrane.Element.UDP.SocketOptions
  alias Membrane.Buffer.Metadata
  use Membrane.Mixins.Log

  def_known_source_pads %{
    :source => {:always, [:any]}
  }

  def_known_sink_pads %{
    :sink => {:always, [:any]}
  }


  @doc false
  def handle_init(%SocketOptions{} = options) do
    {:ok, Map.put_new(options, :socket, nil)}
  end


  @doc false
  def handle_prepare(_prev_state, %{port: port, tos: tos} = state) do
    {:ok, socket} = :gen_udp.open(port, [{:tos, tos}, :binary])
    :gen_udp.controlling_process(socket, self())
    {:ok, %{state | socket: socket}}
  end


  @doc false
  def handle_buffer(:sink, _caps, %Membrane.Buffer{payload: data}, %{socket: socket, remote_address: remote_address, remote_port: remote_port} = state) do
      case :gen_udp.send(socket, remote_address, remote_port, data) do
        :ok ->
          {:ok, state}
        {:error, reason} ->
          {:error, reason, state}
      end
  end


  @doc false
  def handle_other(message, %{remote_port: remote_port, remote_address: remote_address} = state) do

    state = case {remote_address, remote_port} do

      {nil, nil} ->
        case message do
          {:udp, _port, udp_source_address, udp_source_port, _data} ->
            %{state | remote_address: udp_source_address, remote_port: udp_source_port}
          _ -> state
        end

      _ ->
        state
    end


    case message do
      {:udp, port, udp_source_address, udp_source_port, data} ->
        debug("Received UDP packet on port #{inspect(port)} from #{inspect(udp_source_address)}:#{inspect(udp_source_port)}")

        metadata = Metadata.new |>
                   Metadata.put(:udp_source_address, udp_source_address) |>
                   Metadata.put(:udp_source_port, udp_source_port)

        {:ok, [{:send, {:source, %Membrane.Buffer{payload: data, metadata: metadata}}}], state}

      _ ->
        {:error, :invalid_message, state}
    end

  end

end
