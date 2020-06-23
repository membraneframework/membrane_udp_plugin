defmodule Membrane.Element.UDP.Source do
  @moduledoc """
  Element that reads packets from a UDP socket and sends their payloads through the output pad.
  """
  use Membrane.Source

  alias Membrane.Buffer
  alias Membrane.Element.UDP.{CommonSocketBehaviour, Socket}

  def_options local_port_no: [
                type: :integer,
                spec: pos_integer,
                default: 5000,
                description: "A UDP port number used when opening a receiving socket."
              ],
              local_address: [
                type: :ip_address,
                spec: :inet.socket_address(),
                default: :any,
                description: """
                An IP Address on which the socket will listen. It allows to choose which
                network interface to use if there's more than one.
                """
              ],
              recv_buffer_size: [
                type: :integer,
                spec: pos_integer,
                default: 16_384,
                description: """
                Size of the receive buffer. Packages of size greater than this buffer will be truncated
                """
              ]

  def_output_pad :output,
    caps: :any,
    mode: :push

  @impl true
  def handle_init(%__MODULE__{} = opts) do
    socket = %Socket{
      ip_address: opts.local_address,
      port_no: opts.local_port_no,
      sock_opts: [recbuf: opts.recv_buffer_size]
    }

    {:ok, %{local_socket: socket}}
  end

  @impl true
  def handle_other(
        {:udp, _socket_handle, address, port_no, payload},
        %{playback_state: :playing},
        state
      ) do
    metadata =
      Map.new()
      |> Map.put(:udp_source_address, address)
      |> Map.put(:udp_source_port, port_no)
      |> Map.put(:arrival_ts, Membrane.Time.vm_time())

    actions = [buffer: {:output, %Buffer{payload: payload, metadata: metadata}}]

    {{:ok, actions}, state}
  end

  @impl true
  def handle_other({:udp, _socket_handle, _address, _port_no, _payload}, _ctx, state) do
    {:ok, state}
  end

  @impl true
  defdelegate handle_stopped_to_prepared(context, state), to: CommonSocketBehaviour

  @impl true
  defdelegate handle_prepared_to_stopped(context, state), to: CommonSocketBehaviour
end
