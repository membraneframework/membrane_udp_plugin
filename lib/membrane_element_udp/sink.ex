defmodule Membrane.Element.UDP.Sink do
  @moduledoc """
  Element that reads packets from UDP socket and sends their payload through output pad.

  See `options/0` for available options
  """
  use Membrane.Element.Base.Sink
  alias Membrane.{Buffer}
  import Mockery.Macro

  def_options(
    destination_address: [type: :string, description: "IP Address that packets will be sent to"],
    destination_port: [
      type: :integer,
      spec: pos_integer,
      description: "UDP target port"
    ],
    local_address: [type: :string, description: "Local IP Address"],
    local_port: [
      type: :integer,
      spec: pos_integer,
      default: 5000,
      description: "UDP local port"
    ]
  )

  def_input_pads(
    input: [
      caps: :any,
      demand_unit: :buffers
    ]
  )

  # Private API

  @impl true
  def handle_init(%__MODULE__{} = options) do
    {:ok, Map.from_struct(options)}
  end

  @impl true
  def handle_write(
        :input,
        %Buffer{payload: payload},
        _ctx,
        %{
          destination_address: destination_address,
          destination_port: destination_port,
          open_port: port
        } = state
      ) do
    case mockable(Membrane.Element.UDP.CommonPort).send(
           port,
           payload,
           destination_address,
           destination_port
         ) do
      :ok ->
        {:ok, state}

      {:error, _reason} = result ->
        {result, state}
    end
  end

  @impl true
  def handle_stopped_to_prepared(
        _ctx,
        %{
          local_address: address,
          local_port: port
        } = state
      ),
      do: mockable(Membrane.Element.UDP.CommonPort).open(address, port, state)

  @impl true
  def handle_prepared_to_stopped(_ctx, state) do
    mockable(Membrane.Element.UDP.CommonPort).close(state.open_port)
    {:ok, state}
  end
end
