defmodule Membrane.Element.UDP.CommonPortTest do
  use ExUnit.Case, async: false

  alias Membrane.Element.UDP.CommonPort

  test "opens port when not taken and closes" do
    assert {:ok, port} = CommonPort.open({127, 0, 0, 1}, 5000)
    assert :ok = CommonPort.close(port)
  end
end
