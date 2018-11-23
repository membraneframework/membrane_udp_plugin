defmodule Membrane.Element.UDP.Source do
  @moduledoc """
  Element that reads packets from UDP socket and sends their payload through the output pad.

  See `options/0` for available options
  """
  use Membrane.Element.Base.Source
  alias Membrane.Buffer
  alias Membrane.Element.UDP.{Socket, CommonSocketBehaviour}
  import Mockery.Macro

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
  def handle_demand(_pad, _size, __type, _ctx, state) do
    {:ok, state}
  end

  @impl true

  def handle_other({:udp, _socket_handle, address, port_no, payload}, _ctx, state) do
    metadata =
      Map.new()
      |> Map.put(:udp_source_address, address)
      |> Map.put(:udp_source_port, port_no)

    actions = [buffer: {:output, %Buffer{payload: payload, metadata: metadata}}]

    {
      {:ok, actions},
      state
    }
  end

  @impl true
  def handle_stopped_to_prepared(ctx, state) do
    mockable(CommonSocketBehaviour).handle_stopped_to_prepared(ctx, state)
  end

  @impl true
  def handle_prepared_to_stopped(ctx, state) do
    mockable(CommonSocketBehaviour).handle_prepared_to_stopped(ctx, state)
  end
end
