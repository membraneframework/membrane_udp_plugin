defmodule Membrane.Element.UDP.CommonPortTest do
  use ExUnit.Case, async: false

  alias Membrane.Element.UDP.CommonPort

  test "opens port when not taken and closes" do
    assert {:ok, state} = CommonPort.open({127, 0, 0, 1}, 5000, %{socket_handle: nil})
    assert %{socket_handle: nil} = CommonPort.close(state)
  end
end
