defmodule Membrane.UDP.Source do
  @moduledoc """
  Element that reads packets from a UDP socket and sends their payloads through the output pad.

  By receiving a `:close_socket` notification this element will close the socket and send
  `end_of_stream` to it's output pad.
  """
  use Membrane.Source

  alias Membrane.{Buffer, RemoteStream}
  alias Membrane.UDP.{CommonSocketBehaviour, Socket}

  def_options local_port_no: [
                spec: pos_integer(),
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
                spec: pos_integer(),
                default: 1024 * 1024,
                description: """
                Size of the receive buffer. Packages of size greater than this buffer will be truncated
                """
              ],
              pierce_nat_ctx: [
                spec:
                  %{
                    uri: URI.t(),
                    address: :inet.ip_address(),
                    port: pos_integer()
                  }
                  | nil,
                default: nil,
                description: """
                Context necessary to make an attempt to create client-side NAT binding
                by sending an empty datagram from the `#{inspect(__MODULE__)}` to an arbitrary host.

                * If left as `nil`, no attempt will ever be made.
                * If filled in, whenever the pipeline switches playback to `:playing`,
                one datagram (with an empty payload) will be sent from the opened socket
                to the `:port` at `:address` provided via this option.
                If `:address` is not present, it will be parsed from `:uri`.

                Disclaimer: This is a potential vulnerability. Use with caution.
                """
              ],
              local_socket: [
                spec: :gen_tcp.socket() | nil,
                default: nil,
                description: """
                Already connected UDP socket, if provided it will be used instead of creating
                and connecting a new one.
                """
              ]

  def_output_pad :output, accepted_format: %RemoteStream{type: :packetized}, flow_control: :push

  @impl true
  def handle_init(_context, %__MODULE__{} = opts) do
    socket = %Socket{
      ip_address: opts.local_address,
      port_no: opts.local_port_no,
      sock_opts: [recbuf: opts.recv_buffer_size]
    }

    {[], %{local_socket: socket, pierce_nat_ctx: opts.pierce_nat_ctx}}
  end

  @impl true
  def handle_playing(_ctx, %{pierce_nat_ctx: nil} = state) do
    {[stream_format: {:output, %RemoteStream{type: :packetized}}], state}
  end

  @impl true
  def handle_playing(_ctx, %{pierce_nat_ctx: nat_ctx} = state) do
    ip =
      if is_nil(Map.get(nat_ctx, :address)),
        do: parse_address(nat_ctx.uri),
        else: nat_ctx.address

    nat_ctx = Map.put(nat_ctx, :address, ip)

    Socket.send(%Socket{ip_address: ip, port_no: nat_ctx.port}, state.local_socket, <<>>)

    {[stream_format: {:output, %RemoteStream{type: :packetized}}],
     %{state | pierce_nat_ctx: nat_ctx}}
  end

  @impl true
  def handle_parent_notification(:close_socket, _ctx, state) do
    Socket.close(state.local_socket)
    {[end_of_stream: :output], state}
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

  defp parse_address(uri) do
    hostname =
      URI.parse(uri)
      |> Map.get(:host)
      |> to_charlist()

    Enum.find_value([:inet, :inet6, :local], fn addr_family ->
      case :inet.getaddr(hostname, addr_family) do
        {:ok, address} -> address
        {:error, _reason} -> false
      end
    end)
  end
end
