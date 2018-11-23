defmodule Membrane.Element.UDP.SourceTest do
  use ExUnit.Case
  use Mockery

  alias Membrane.Element.UDP.Source

  def state(_ctx) do
    %{
      state: %{
        address: {127, 0, 0, 1},
        port: 5000,
        socket_handle: nil
      }
    }
  end

  setup_all :state

  test "parses udp message", %{state: state} do
    example_binary_payload = "Hi there, I am binary"
    sender_port = 6666
    sender_address = {192, 168, 0, 1}
    message = {:udp, 5000, sender_address, sender_port, example_binary_payload}
    assert {{:ok, actions}, ^state} = Source.handle_other(message, nil, state)
    assert {:output, buffer} = Keyword.get(actions, :buffer)

    assert %Membrane.Buffer{
             payload: example_binary_payload,
             metadata: %{udp_source_address: sender_address, udp_source_port: sender_port}
           } == buffer
  end
end
