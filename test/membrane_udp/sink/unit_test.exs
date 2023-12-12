defmodule Membrane.UDP.SinkUnitTest do
  use ExUnit.Case
  use Mockery

  alias Membrane.Buffer
  alias Membrane.UDP.{Endpoint, Sink, Socket}

  @local_address {127, 0, 0, 1}

  for module <- [Endpoint, Sink] do
    describe "#{inspect(module)} element" do
      test "handle_buffer/4 calls send and demands more data" do
        mock(Socket, [send: 3], :ok)
        payload_data = "binary data"
        local_socket = %Socket{port_no: 1234, ip_address: @local_address}
        dst_socket = %Socket{port_no: 4321, ip_address: @local_address}

        state = %{
          local_socket: local_socket,
          dst_socket: dst_socket
        }

        assert unquote(module).handle_buffer(:input, %Buffer{payload: payload_data}, nil, state) ==
                 {[], state}

        assert_called(Socket, :send, [^dst_socket, ^local_socket, ^payload_data])
      end
    end
  end
end
