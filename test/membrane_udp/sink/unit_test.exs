defmodule Membrane.UDP.SinkUnitTest do
  use ExUnit.Case
  use Mockery

  alias Membrane.Buffer
  alias Membrane.UDP.{Endpoint, Sink, Socket, SocketFactory}

  for module <- [Endpoint, Sink] do
    describe "#{inspect(module)} element" do
      test "handle_buffer/4 calls send and demands more data" do
        mock(Socket, [send: 3], :ok)
        payload_data = "binary data"
        local_socket = SocketFactory.local_socket(1234)
        dst_socket = SocketFactory.local_socket(4321)

        state = %{
          local_socket: local_socket,
          dst_socket: dst_socket
        }

        assert unquote(module).handle_buffer(:input, %Buffer{payload: payload_data}, nil, state) ==
                 {[demand: :input], state}

        assert_called(Socket, :send, [^dst_socket, ^local_socket, ^payload_data])
      end

      test "demands data when starting to play" do
        assert {commands, nil} = unquote(module).handle_playing(nil, nil)

        assert Keyword.fetch(commands, :demand) == {:ok, :input}
      end
    end
  end
end
