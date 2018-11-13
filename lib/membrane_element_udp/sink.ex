defmodule Membrane.Element.UDP.Sink do
  @moduledoc """
  Element that reads packets from UDP socket and sends their payload through output pad.

  See `options/0` for available options
  """
  use Membrane.Element.Base.Sink
  alias Membrane.{Buffer}

  @f Mockery.of(Membrane.Element.UDP.CommonPort)

  def_options(
    address: [type: :string, description: "IP Address"],
    port: [
      type: :integer,
      spec: pos_integer,
      default: 5000,
      description: "UDP target port"
    ]
  )

  def_input_pads(
    input: [
      caps: :any
    ]
  )

  # Private API

  @impl true
  def handle_init(%__MODULE__{address: address, port: port}) do
    {:ok,
     %{
       address: address,
       port: port,
       open_port: nil
     }}
  end

  @impl true
  def handle_write(:input, %Buffer{payload: payload}, _ctx, %{
        address: target_address,
        port: target_port,
        open_port: port
      }) do
    @f.send(port, payload, target_address, target_port)
  end

  @impl true
  def handle_stopped_to_prepared(_ctx, %{
        address: address,
        port: port
      }),
      do: @f.open(address, port)

  @impl true
  def handle_prepared_to_stopped(_ctx, state) do
    case @f.close(state.open_port) do
      :ok -> {:ok, state}
      {:error, cause} -> {:error, cause}
    end
  end
end
