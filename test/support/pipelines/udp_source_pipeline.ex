defmodule SourcePipeline do
  @moduledoc false

  alias Membrane.{Element, Pipeline}
  alias Membrane.Integration.TestingPipeline

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
      test_sink: %Element.TestSink{test_process: test_process_pid, name: :udp_source}
    ]

    links = %{
      {:udp_source, :output} => {:test_sink, :input, pull_buffer: [toilet: true]}
    }

    Pipeline.start_link(TestingPipeline, %{
      elements: elements,
      links: links,
      test_process: test_process_pid
    })
  end
end
