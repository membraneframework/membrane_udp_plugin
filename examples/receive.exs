require Logger
Logger.configure(level: :info)

Mix.install([
  {:membrane_core, "~> 1.0"},
  {:membrane_udp_plugin, "~> 0.13.0"},
  {:membrane_file_plugin, "~> 0.16"}
])

defmodule UDPDemo.Receive do
  use Membrane.Pipeline

  alias Membrane.{File, UDP}

  @impl true
  def handle_init(_ctx, _opts) do
    spec =
      child(%UDP.Source{
        local_address: {127, 0, 0, 1},
        local_port_no: 5001
      })
      |> child(%File.Sink{location: "/tmp/udp-recv.mp4"})

    {[spec: spec], %{}}
  end
end

{:ok, _supervisor, _pipeline} = Membrane.Pipeline.start_link(UDPDemo.Receive)

Logger.info("UDP receiver started")
Process.sleep(:infinity)
