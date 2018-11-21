defmodule Membrane.Element.TestSink do
  @moduledoc false
  use Membrane.Element.Base.Sink

  def_options test_process: [
                type: :any
              ],
              name: [
                type: :string
              ]

  def_input_pads input: [
                   caps: :any,
                   demand_unit: :buffers
                 ]

  @impl true
  def handle_init(%__MODULE__{} = options) do
    state =
      options
      |> Map.from_struct()

    {:ok, state}
  end

  @impl true
  def handle_write(:input, buffer, _ctx, %{test_process: pid, name: name} = state) do
    send(pid, {name, buffer})
    {{:ok, demand: :input}, state}
  end
end
