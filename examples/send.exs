require Logger
Logger.configure(level: :info)

Mix.install([
  {:membrane_core, "~> 1.0"},
  {:membrane_hackney_plugin, "~> 0.11"},
  {:membrane_udp_plugin, "~> 0.13.0"}
])

defmodule UDPDemo.Send do
  use Membrane.Pipeline

  alias Membrane.{File, UDP, Hackney}

  @impl true
  def handle_init(_ctx, _opts) do
    spec =
      child(%Hackney.Source{
        location:
          "https://archive.org/download/Rick_Astley_Never_Gonna_Give_You_Up/Rick_Astley_Never_Gonna_Give_You_Up.mp4",
        hackney_opts: [follow_redirect: true]
      })
      |> child(%UDP.Sink{
        destination_address: {127, 0, 0, 1},
        destination_port_no: 5001,
        local_address: {127, 0, 0, 1}
      })

    {[spec: spec], %{}}
  end
end

{:ok, _supervisor, _pipeline} = Membrane.Pipeline.start_link(UDPDemo.Send)

Logger.info("UDP sender started")
Process.sleep(:infinity)
