defmodule Membrane.Element.UDP.SinkTest do
  use ExUnit.Case
  use Mockery

  alias Membrane.Element.UDP.Sink
  alias Membrane.Element.UDP.CommonPort
  alias Membrane.Buffer

  @local_address {127, 0, 0, 1}

  def state(_ctx) do
    {:ok, socket_handle} = CommonPort.open(@local_address, 5000)

    %{
      state: %{
        destination_address: @local_address,
        destination_port: 5001,
        local_address: @local_address,
        local_port: 5000,
        socket_handle: socket_handle
      }
    }
  end

  setup_all :state

  test "Sends udp packet", %{
    state:
      %{
        destination_address: destination_address,
        destination_port: destination_port,
        socket_handle: port
      } = state
  } do
    payload = "A lot of laughs"
    {:ok, receving_socket} = CommonPort.open(destination_address, destination_port)
    Sink.handle_write(:input, %Buffer{payload: payload}, nil, state)

    assert_receive {:udp, _, {127, 0, 0, 1}, 5000, ^payload}
    CommonPort.close(receving_socket)
    CommonPort.close(port)
  end
end
