defmodule Membrane.UDP.Endpoint do
  @moduledoc """
  Element that sends buffers received on the input pad over a UDP socket and
  reads packets from a UDP socket and sends their payloads through the output pad.
  """
  use Membrane.Endpoint

  import Mockery.Macro

  alias Membrane.{Buffer, RemoteStream}
  alias Membrane.UDP.{CommonSocketBehaviour, Socket}

  def_options destination_address: [
                spec: :inet.ip_address(),
                description: "An IP Address that the packets will be sent to."
              ],
              destination_port_no: [
                spec: :inet.port_number(),
                description: "A UDP port number of a target."
              ],
              local_address: [
                spec: :inet.socket_address(),
                default: :any,
                description: """
                This address is used in two cases:
                * An IP Address set for a UDP socket used to sent packets.
                * An IP Address on which the socket will listen.
                In both cases, it allows to choose which network interface to use if there's more than one.
                """
              ],
              local_port_no: [
                spec: :inet.port_number(),
                default: 0,
                description: """
                A UDP port number used when opening a receiving socket and for sending packets.
                """
              ],
              recv_buffer_size: [
                spec: pos_integer(),
                default: 1024 * 1024,
                description: """
                Size of the receive buffer. Packages of size greater than this buffer will be truncated
                """
              ]

  def_input_pad :input, accepted_format: _any

  def_output_pad :output, accepted_format: %RemoteStream{type: :packetized}, flow_control: :push

  # Private API

  @impl true
  def handle_init(_context, %__MODULE__{} = opts) do
    %__MODULE__{
      destination_address: dst_address,
      destination_port_no: dst_port_no,
      local_address: local_address,
      local_port_no: local_port_no
    } = opts

    state = %{
      dst_socket: %Socket{
        ip_address: dst_address,
        port_no: dst_port_no
      },
      local_socket: %Socket{
        ip_address: local_address,
        port_no: local_port_no,
        sock_opts: [recbuf: opts.recv_buffer_size]
      }
    }

    {[], state}
  end

  @impl true
  def handle_playing(_context, state) do
    {[stream_format: {:output, %RemoteStream{type: :packetized}}], state}
  end

  @impl true
  def handle_buffer(:input, %Buffer{payload: payload}, _context, state) do
    %{dst_socket: dst_socket, local_socket: local_socket} = state

    case mockable(Socket).send(dst_socket, local_socket, payload) do
      :ok -> {[], state}
      {:error, cause} -> raise "Error sending UDP packet, reason: #{inspect(cause)}"
    end
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
end
