defmodule Membrane.UDP.Sink do
  @moduledoc """
  Element that sends buffers received on the input pad over a UDP socket.
  """
  use Membrane.Sink

  import Mockery.Macro

  alias Membrane.Buffer
  alias Membrane.UDP.{CommonSocketBehaviour, Socket}

  def_options destination_address: [
                type: :ip_address,
                spec: :inet.ip_address(),
                description: "An IP Address that the packets will be sent to."
              ],
              destination_port_no: [
                type: :integer,
                spec: :inet.port_number(),
                description: "A UDP port number of a target."
              ],
              local_address: [
                type: :ip_address,
                spec: :inet.socket_address(),
                default: :any,
                description: """
                An IP Address set for a UDP socket used to sent packets. It allows to specify which
                network interface to use if there's more than one.
                """
              ],
              local_port_no: [
                type: :integer,
                spec: :inet.port_number(),
                default: 0,
                description: """
                A UDP port number for the socket used to sent packets. If set to `0` (default)
                the underlying OS will assign a free UDP port.
                """
              ]

  def_input_pad :input,
    caps: :any,
    demand_unit: :buffers

  # Private API

  @impl true
  def handle_init(%__MODULE__{} = options) do
    %__MODULE__{
      destination_address: dst_address,
      destination_port_no: dst_port_no,
      local_address: local_address,
      local_port_no: local_port_no
    } = options

    state = %{
      dst_socket: %Socket{
        ip_address: dst_address,
        port_no: dst_port_no
      },
      local_socket: %Socket{
        ip_address: local_address,
        port_no: local_port_no
      }
    }

    {:ok, state}
  end

  @impl true
  def handle_prepared_to_playing(_context, state) do
    {{:ok, demand: :input}, state}
  end

  @impl true
  def handle_write(:input, %Buffer{payload: payload}, _context, state) do
    %{dst_socket: dst_socket, local_socket: local_socket} = state

    case mockable(Socket).send(dst_socket, local_socket, payload) do
      :ok -> {{:ok, demand: :input}, state}
      {:error, cause} -> {{:error, cause}, state}
    end
  end

  @impl true
  defdelegate handle_stopped_to_prepared(context, state), to: CommonSocketBehaviour

  @impl true
  defdelegate handle_prepared_to_stopped(context, state), to: CommonSocketBehaviour
end
