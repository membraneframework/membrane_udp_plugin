defmodule Membrane.Element.UDP.Source do
  use Membrane.Element.Base.Source
  alias Membrane.{Buffer, Event}
  use Membrane.Helper

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

  def_known_source_pads(source: {:always, :pull, :any})

  # Private API

  @impl true
  def handle_init(%__MODULE__{address: address, port: port}) do
    {:ok,
     %{
       address: address,
       port: port,
       open_port: nil,
       received_packets: []
     }}
  end

  @impl true
  def handle_prepare(:stopped, %{
        address: address,
        port: port
      }),
      do: @f.open(address, port)

  def handle_prepare(_, state), do: {:ok, state}

  @impl true
  def handle_demand1(_pad, _context, state),
    do: {:ok, state}

  @impl true
  def handle_demand(pad, size, :buffers, context, state) do
    {:ok, state}
  end

  @impl true
  def handle_other({:udp, _port, _address, _, payload}, state) do
    actions = [buffer: {:source, %Buffer{payload: payload}}]

    {
      {:ok, actions},
      state
    }
  end

  @impl true
  def handle_stop(state), do: @f.close(state)
end
