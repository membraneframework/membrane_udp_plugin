defmodule SinkPipeline do
  @moduledoc false
  use Membrane.Pipeline

  alias Membrane.Element
  alias Membrane.Element.UDP.SocketFactory
  alias Membrane.Integration.TestingPipeline

  @local_address SocketFactory.local_address()

  def start_link(%{
        sink_local_port_no: sink_local_port_no,
        sink_destination_port_no: sink_destination_port_no,
        test_data: data
      }) do
    elements = [
      udp_sink: %Element.UDP.Sink{
        destination_address: @local_address,
        destination_port_no: sink_destination_port_no,
        local_address: @local_address,
        local_port_no: sink_local_port_no
      },
      test_source: %Membrane.Element.TestSource{data: data}
    ]

    links = %{
      {:test_source, :output} => {:udp_sink, :input}
    }

    Pipeline.start_link(TestingPipeline, %{
      elements: elements,
      links: links,
      test_process: self()
    })
  end
end
