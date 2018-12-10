defmodule SourcePipeline do
  @moduledoc false

  alias Membrane.{Element, Pipeline}
  alias Membrane.Testing

  @local_address {127, 0, 0, 1}

  def start_link(%{
        port_no: port_no
      }) do
    test_process_pid = self()

    elements = [
      udp_source: %Element.UDP.Source{
        local_address: @local_address,
        local_port_no: port_no
      },
      test_sink: %Testing.Sink{target: test_process_pid}
    ]

    links = %{
      {:udp_source, :output} => {:test_sink, :input, pull_buffer: [toilet: true]}
    }

    Pipeline.start_link(Testing.Pipeline, %Testing.Pipeline.Options{
      elements: elements,
      links: links,
      test_process: test_process_pid,
      monitored_callbacks: [:handle_prepared_to_playing]
    })
  end
end
