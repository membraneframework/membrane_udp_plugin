defmodule SourcePipeline do
  @moduledoc false
  use Membrane.Pipeline
  alias Membrane.Element

  @local_address {127, 0, 0, 1}

  @impl true
  def handle_init(%{
        port_no: port_no,
        test_process: pid
      }) do
    elements = [
      udp_source: %Element.UDP.Source{
        local_address: @local_address,
        local_port_no: port_no
      },
      test_sink: %Element.TestSink{test_process: pid, name: :udp_source}
    ]

    links = %{
      {:udp_source, :output} => {:test_sink, :input, pull_buffer: [toilet: true]}
    }

    spec = %Membrane.Pipeline.Spec{
      children: elements,
      links: links
    }

    {{:ok, spec}, %{test_process: pid}}
  end

  @impl true
  def handle_prepared_to_playing(%{test_process: pid} = state) do
    send(pid, {__MODULE__, :playing})
    {:ok, state}
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
