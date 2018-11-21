defmodule Membrane.Element.UDP.SinkTest do
  use ExUnit.Case
  use Mockery

  alias Membrane.Element.UDP.Sink
  alias Membrane.Element.UDP.CommonPort
  alias Membrane.Buffer

  @local_address {127, 0, 0, 1}

  def state(_ctx) do
    {:ok, state} =
      CommonPort.open(%{
        destination_address: @local_address,
        destination_port_no: 5001,
        local_address: @local_address,
        local_port_no: 5000,
        socket_handle: nil
      })

    %{
      state: state
    }
  end

  setup_all :state

  test "Sends udp packet", %{
    state:
      %{
        destination_address: destination_address,
        destination_port_no: destination_port
      } = state
  } do
    payload = "A lot of laughs"

    {:ok, receving_socket} =
      :gen_udp.open(destination_port, [{:ip, destination_address}, :binary, {:active, true}])

    Sink.handle_write(:input, %Buffer{payload: payload}, nil, state)

    assert_receive {:udp, _, {127, 0, 0, 1}, 5000, ^payload}
    :gen_udp.close(receving_socket)
    CommonPort.close(state)
  end
end
