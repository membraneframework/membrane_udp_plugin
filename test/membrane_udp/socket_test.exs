defmodule Membrane.UDP.SocketTest do
  use ExUnit.Case, async: false

  alias Membrane.UDP.Socket

  describe "open" do
    test "with explicit port and address" do
      sock = %Socket{port_no: 50_666, ip_address: {127, 0, 0, 1}}
      assert {:ok, new_sock} = sock |> Socket.open()
      assert new_sock.ip_address == sock.ip_address
      assert new_sock.port_no == sock.port_no

      assert new_sock.socket_handle |> :inet.sockname() ==
               {:ok, {new_sock.ip_address, new_sock.port_no}}
    end

    test "with port 0 and `:any` IPv6 address" do
      sock = %Socket{port_no: 0, ip_address: :any, sock_opts: [:inet6]}
      assert {:ok, new_sock} = sock |> Socket.open()
      assert new_sock.ip_address == {0, 0, 0, 0, 0, 0, 0, 0}
      assert new_sock.port_no != 0

      assert new_sock.socket_handle |> :inet.sockname() ==
               {:ok, {new_sock.ip_address, new_sock.port_no}}
    end

    test "with port 0 and `:loopback` IPv4 address" do
      sock = %Socket{port_no: 0, ip_address: :loopback, sock_opts: [:inet]}
      assert {:ok, new_sock} = sock |> Socket.open()
      assert new_sock.ip_address == {127, 0, 0, 1}
      assert new_sock.port_no != 0

      assert new_sock.socket_handle |> :inet.sockname() ==
               {:ok, {new_sock.ip_address, new_sock.port_no}}
    end
  end
end
