defmodule Membrane.Element.UDP.Sink do
  @moduledoc """
  Element that reads packets from UDP socket and sends their payload through output pad.

  See `options/0` for available options
  """
  use Membrane.Element.Base.Sink
  alias Membrane.Buffer
  alias Membrane.Element.UDP.CommonPort
  import Mockery.Macro

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

  def_input_pads input: [
                   caps: :any,
                   demand_unit: :buffers
                 ]

  # Private API

  @impl true
  def handle_init(%__MODULE__{} = options) do
    state =
      options
      |> Map.from_struct()
      |> Map.put(:socket_handle, nil)

    {:ok, state}
  end

  @impl true
  def handle_prepared_to_playing(_ctx, state) do
    {{:ok, demand: :input}, state}
  end

  @impl true
  def handle_write(
        :input,
        %Buffer{payload: payload},
        _ctx,
        state
      ) do
    mockable(CommonPort).send(payload, state)
  end

  @impl true
  def handle_stopped_to_prepared(
        _ctx,
        %{
          local_address: address,
          local_port_no: port_no
        } = state
      ),
      do: mockable(CommonPort).open(state)

  @impl true
  def handle_prepared_to_stopped(_ctx, state) do
    mockable(CommonPort).close(state)
  end
end
