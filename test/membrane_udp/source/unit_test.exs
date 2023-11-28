defmodule Membrane.UDP.SourceTest do
  use ExUnit.Case

  alias Membrane.UDP.{Endpoint, Source}

  test "parses udp message Source element" do
    example_binary_payload = "Hi there, I am binary"
    sender_port = 6666
    sender_address = {192, 168, 0, 1}
    state = :unchanged
    message = {:udp, 5000, sender_address, sender_port, example_binary_payload}

    assert {actions, ^state} =
             Source.handle_parent_notification(message, %{playback: :playing}, state)

    assert {:output, buffer} = Keyword.get(actions, :buffer)

    assert %Membrane.Buffer{
             payload: ^example_binary_payload,
             metadata: %{
               udp_source_address: ^sender_address,
               udp_source_port: ^sender_port,
               arrival_ts: arrival_ts
             }
           } = buffer

    assert_in_delta(arrival_ts, Membrane.Time.vm_time(), 2 |> Membrane.Time.milliseconds())
  end

  test "parses udp message Endpoint element" do
    example_binary_payload = "Hi there, I am binary"
    sender_port = 6666
    sender_address = {192, 168, 0, 1}
    state = :unchanged
    message = {:udp, 5000, sender_address, sender_port, example_binary_payload}

    assert {actions, ^state} =
             Endpoint.handle_parent_notification(message, %{playback: :playing}, state)

    assert {:output, buffer} = Keyword.get(actions, :buffer)

    assert %Membrane.Buffer{
             payload: ^example_binary_payload,
             metadata: %{
               udp_source_address: ^sender_address,
               udp_source_port: ^sender_port,
               arrival_ts: arrival_ts
             }
           } = buffer

    assert_in_delta(arrival_ts, Membrane.Time.vm_time(), 2 |> Membrane.Time.milliseconds())
  end
end
