defmodule Membrane.Element.UDP.CommonPortTest do
  use ExUnit.Case, async: false

  alias Membrane.Element.UDP.CommonPort

  test "opens port when not taken and closes" do
    assert {:ok, state} =
             CommonPort.open(%{
               socket_handle: nil,
               local_address: {127, 0, 0, 1},
               local_port_no: 5000
             })

    assert {:ok, %{socket_handle: nil}} = CommonPort.close(state)
  end
end
