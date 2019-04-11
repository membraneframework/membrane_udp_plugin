defmodule Membrane.Element.UDP.Sink do
  @moduledoc """
  Element that reads packets from UDP socket and sends their payload through output pad.

  See `options/0` for available options
  """
  use Membrane.Element.Base.Sink

  import Mockery.Macro

  alias Membrane.Buffer
  alias Membrane.Element.UDP.{CommonSocketBehaviour, Socket}

  def_options destination_address: [
                type: :string,
                description: "IP Address that packets will be sent to"
              ],
              destination_port_no: [
                type: :integer,
                spec: pos_integer,
                description: "UDP target port"
              ],
              local_address: [type: :string, description: "Local IP Address"],
              local_port_no: [
                type: :integer,
                spec: pos_integer,
                default: 5000,
                description: "UDP local port"
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
