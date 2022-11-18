defmodule Membrane.UDP.Source do
  @moduledoc """
  Element that reads packets from a UDP socket and sends their payloads through the output pad.
  """
  use Membrane.Source

  alias Membrane.{Buffer, RemoteStream}
  alias Membrane.UDP.{CommonSocketBehaviour, Socket}

  def_options(
    local_port_no: [
      spec: pos_integer,
      default: 5000,
      description: "A UDP port number used when opening a receiving socket."
    ],
    local_address: [
      spec: :inet.socket_address(),
      default: :any,
      description: """
      An IP Address on which the socket will listen. It allows to choose which
      network interface to use if there's more than one.
      """
    ],
    recv_buffer_size: [
      spec: pos_integer,
      default: 16_384,
      description: """
      Size of the receive buffer. Packages of size greater than this buffer will be truncated
      """
    ]
  )

  def_output_pad(:output, accepted_format: %RemoteStream{type: :packetized}, mode: :push)

  @impl true
  def handle_init(_context, %__MODULE__{} = opts) do
    socket = %Socket{
      ip_address: opts.local_address,
      port_no: opts.local_port_no,
      sock_opts: [recbuf: opts.recv_buffer_size]
    }

    {[], %{local_socket: socket}}
  end

  @impl true
  def handle_playing(_ctx, state) do
    {[stream_format: {:output, %RemoteStream{type: :packetized}}], state}
  end

  @impl true
  def handle_parent_notification(
        {:udp, _socket_handle, _addr, _port_no, _payload} = meta,
        ctx,
        state
      ) do
    handle_info(meta, ctx, state)
  end

  @impl true
  def handle_info(
        {:udp, _socket_handle, address, port_no, payload},
        %{playback: :playing},
        state
      ) do
    metadata =
      Map.new()
      |> Map.put(:udp_source_address, address)
      |> Map.put(:udp_source_port, port_no)
      |> Map.put(:arrival_ts, Membrane.Time.vm_time())

    actions = [buffer: {:output, %Buffer{payload: payload, metadata: metadata}}]

    {actions, state}
  end

  @impl true
  def handle_info(
        {:udp, _socket_handle, _address, _port_no, _payload},
        _ctx,
        state
      ) do
    {[], state}
  end

  @impl true
  defdelegate handle_setup(context, state), to: CommonSocketBehaviour

  @impl true
  defdelegate handle_terminate_request(context, state), to: CommonSocketBehaviour
end
