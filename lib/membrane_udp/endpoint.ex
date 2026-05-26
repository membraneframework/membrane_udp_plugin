defmodule Membrane.UDP.Endpoint do
  @moduledoc """
  Element that sends buffers received on the input pad over a UDP socket and
  reads packets from a UDP socket and sends their payloads through the output pad.

  The local and destination addresses are provided at init via the element's
  options; the destination can additionally be changed at runtime by returning
  a `:notify_child` action with a `t:set_destination_notification/0` from the parents callback:

  ```elixir
  {[notify_child: {:endpoint, {:set_destination, peer_ip, peer_port}}], state}
  ```

  With `latch?: true`, the outbound destination automatically follows the
  source of the most recent inbound packet. This is useful for talking to
  peers whose source address may differ from the initially configured
  destination (e.g. peers behind NAT) or change over time (e.g. mobile peers
  roaming networks).
  """
  use Membrane.Endpoint, flow_control_hints?: false

  require Membrane.Logger

  alias Membrane.{Buffer, RemoteStream}
  alias Membrane.UDP.{CommonSocketBehaviour, Socket}

  @type destination_port :: 1..65_535

  @type set_destination_notification ::
          {:set_destination, :inet.ip_address(), destination_port()}

  def_options destination_address: [
                spec: :inet.ip_address(),
                description: "An IP Address that the packets will be sent to."
              ],
              destination_port_no: [
                spec: destination_port(),
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
              ],
              latch?: [
                spec: boolean(),
                default: false,
                description: """
                When true, the outbound destination follows the source of the most
                recent inbound packet. Until the first inbound packet arrives,
                outbound goes to the configured destination (the `destination_*`
                options, possibly overridden via `:set_destination`).
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

    :ok = CommonSocketBehaviour.validate_destination!(dst_address, dst_port_no)

    state = %{
      dst_socket: %Socket{
        ip_address: dst_address,
        port_no: dst_port_no
      },
      local_socket: %Socket{
        ip_address: local_address,
        port_no: local_port_no,
        sock_opts: [recbuf: opts.recv_buffer_size]
      },
      latch?: opts.latch?
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

    case Socket.send(dst_socket, local_socket, payload) do
      :ok -> {[], state}
      {:error, cause} -> raise "Error sending UDP packet, reason: #{inspect(cause)}"
    end
  end

  @impl true
  def handle_parent_notification({:set_destination, ip, port}, _ctx, state) do
    :ok = CommonSocketBehaviour.validate_destination!(ip, port)

    if state.latch? do
      Membrane.Logger.warning("""
      #{inspect({:set_destination, ip, port})}} received while :latch? option was set to true;
      the next inbound packet might overwrite this destination"
      """)
    end

    state =
      state
      |> put_in([:dst_socket, :ip_address], ip)
      |> put_in([:dst_socket, :port_no], port)

    {[], state}
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
    state =
      if state.latch? and
           (state.dst_socket.ip_address != address or state.dst_socket.port_no != port_no) do
        Membrane.Logger.debug(
          "latch: outbound destination updated to #{:inet.ntoa(address)}:#{port_no}"
        )

        state
        |> put_in([:dst_socket, :ip_address], address)
        |> put_in([:dst_socket, :port_no], port_no)
      else
        state
      end

    metadata = %{
      udp_source_address: address,
      udp_source_port: port_no,
      arrival_ts: Membrane.Time.vm_time()
    }

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
