defmodule Membrane.Element.UDP.Source do
  @moduledoc """
  Element that reads packets from UDP socket and sends their payload through output pad.

  See `options/0` for available options
  """
  use Membrane.Element.Base.Source
  alias Membrane.Buffer
  alias Membrane.Element.UDP.CommonPort
  import Mockery.Macro

  def_options address: [type: :string, description: "IP Address"],
              port_no: [
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
  def handle_init(%__MODULE__{address: address, port_no: port_no}) do
    {:ok,
     %{
       address: address,
       port_no: port_no,
       socket_handle: nil
     }}
  end

  @impl true
  def handle_stopped_to_prepared(
        _ctx,
        %{
          address: address,
          port_no: port_no
        } = state
      ),
      do: mockable(CommonPort).open(address, port_no, state)

  @impl true
  def handle_demand(_pad, _size, _, _ctx, state) do
    {:ok, state}
  end

  @impl true

  def handle_other({:udp, _, address, port_no, payload}, _, state) do
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
  def handle_prepared_to_stopped(_ctx, state) do
    mockable(CommonPort).close(state)
  end
end
