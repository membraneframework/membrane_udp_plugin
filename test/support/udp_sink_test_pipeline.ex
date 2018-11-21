defmodule SinkPipeline do
  @moduledoc false
  use Membrane.Pipeline
  alias Membrane.Element

  @local_address {127, 0, 0, 1}

  @impl true
  def handle_init(%{
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

    spec = %Membrane.Pipeline.Spec{
      children: elements,
      links: links
    }

    {{:ok, spec}, %{}}
  end

  @impl true
  def handle_notification({:end_of_stream, :input}, :sink, %{pid: pid} = state) do
    send(pid, :eos)
    {:ok, state}
  end

  def handle_notification(_msg, _name, state) do
    {:ok, state}
  end
end
