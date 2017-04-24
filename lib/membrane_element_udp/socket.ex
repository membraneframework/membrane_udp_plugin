defmodule Membrane.Element.UDP.Socket do
  @moduledoc """
  Element that can be used to read from and write to UDP sockets.

  It will bind to local address:port specified as `:local_address` and `:local_port`
  fields of the `Membrane.Element.UDP.SocketOptions` struct and just send all
  received buffers to the source pad.

  It will also send all received buffers on the sink pad to destination specified
  as `:remote_address` and `:remote_port` in the
  `Membrane.Element.UDP.SocketOptions` struct.

  If remote peer is not specified in `Membrane.Element.UDP.SocketOptions` struct,
  it will remember address and port of the first received packet.
    """

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
  def handle_prepare(:stopped, %{local_port: port, local_address: address, tos: tos} = state) do
    {:ok, socket} = :gen_udp.open(port, [{:ip, address}, {:tos, tos}, :binary])
    :gen_udp.controlling_process(socket, self())
    {:ok, %{state | socket: socket}}
  end


  @doc false
  def handle_prepare(:playing, %{socket: socket} = state) do
    :ok = :gen_udp.close(socket)
    {:ok, %{state | socket: nil}}
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

    state = case message do
      {:udp, _port, udp_source_address, udp_source_port, _data} ->
        %{state | remote_address: udp_source_address, remote_port: udp_source_port}
      _ -> state
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
