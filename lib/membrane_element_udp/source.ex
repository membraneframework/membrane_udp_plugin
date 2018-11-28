defmodule Membrane.Element.UDP.Source do
  @moduledoc """
  Element that reads packets from UDP socket and sends their payload through the output pad.

  See `options/0` for available options
  """
  use Membrane.Element.Base.Source
  alias Membrane.Buffer
  alias Membrane.Element.UDP.{CommonSocketBehaviour, Socket}

  def_options local_address: [type: :string, description: "IP Address"],
              local_port_no: [
                type: :integer,
                spec: pos_integer,
                default: 5000,
                description: "UDP target port"
              ]

  def_output_pads output: [
                    caps: :any,
                    mode: :push
                  ]

  # Private API

  @impl true
  def handle_init(%__MODULE__{local_address: ip_address, local_port_no: port_no}) do
    {:ok, %{local_socket: %Socket{ip_address: ip_address, port_no: port_no}}}
  end

  @impl true
  def handle_demand(_pad, _size, _type, _context, state) do
    {:ok, state}
  end

  @impl true

  def handle_other({:udp, _socket_handle, address, port_no, payload}, _context, state) do
    metadata =
      Map.new()
      |> Map.put(:udp_source_address, address)
      |> Map.put(:udp_source_port, port_no)

    actions = [buffer: {:output, %Buffer{payload: payload, metadata: metadata}}]

    {{:ok, actions}, state}
  end

  @impl true
  defdelegate handle_stopped_to_prepared(context, state), to: CommonSocketBehaviour

  @impl true
  defdelegate handle_prepared_to_stopped(context, state), to: CommonSocketBehaviour
end
