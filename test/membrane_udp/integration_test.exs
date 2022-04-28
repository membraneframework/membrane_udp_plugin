defmodule Membrane.UDP.IntegrationTest do
  use ExUnit.Case, async: false

  import Membrane.Testing.Assertions

  alias Membrane.{Buffer, Testing}
  alias Membrane.Testing.Pipeline
  alias Membrane.UDP

  @target_port 5000
  @localhostv4 {127, 0, 0, 1}

  @payload_frames 50

  test "send and receive using 2 pipelines" do
    payload = 1..@payload_frames |> Enum.map(&inspect/1)

    {:ok, receiver} =
      Pipeline.start_link(%Pipeline.Options{
        elements: [
          source: %UDP.Source{local_port_no: @target_port, local_address: @localhostv4},
          sink: %Testing.Sink{}
        ]
      })

    assert_pipeline_notified(receiver, :source, {:connection_info, @localhostv4, @target_port})

    assert_pipeline_playback_changed(receiver, :prepared, :playing)

    {:ok, sender} =
      Pipeline.start_link(%Pipeline.Options{
        elements: [
          source: %Testing.Source{output: payload},
          sink: %UDP.Sink{destination_port_no: @target_port, destination_address: @localhostv4}
        ]
      })

    assert_pipeline_notified(
      sender,
      :sink,
      {:connection_info, {0, 0, 0, 0}, _some_ephemeral_port}
    )

    assert_end_of_stream(sender, :sink)

    1..@payload_frames
    |> Enum.each(fn x ->
      payload = inspect(x)
      assert_sink_buffer(receiver, :sink, %Buffer{payload: ^payload})
    end)

    Pipeline.terminate(sender, blocking?: true)
    Pipeline.terminate(receiver, blocking?: true)
  end
end
