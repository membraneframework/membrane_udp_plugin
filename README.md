# Membrane UDP plugin

[![Hex.pm](https://img.shields.io/hexpm/v/membrane_udp_plugin.svg)](https://hex.pm/packages/membrane_udp_plugin)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_udp_plugin/)
[![CircleCI](https://circleci.com/gh/membraneframework/membrane_udp_plugin.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane_udp_plugin)

This package provides UDP Source and Sink, that read and write to UDP sockets.

## Installation

Add the following line to your `deps` in `mix.exs`. Run `mix deps.get`.

```elixir
	{:membrane_udp_plugin, "~> 0.10.0"}
```

## Usage example

The example below shows 2 pipelines. `UDPDemo.Send` downloads an example file over HTTP and
sends it over UDP socket via localhost:

```elixir
defmodule UDPDemo.Send do
  use Membrane.Pipeline

  alias Membrane.{Hackney, UDP}
  alias Membrane.Pipeline.Spec

  def handle_init(_) do
    children = [
      source: %Hackney.Source{
        location: "https://membraneframework.github.io/static/video-samples/test-video.h264"
      },
      udp: %UDP.Sink{
        destination_address: {127, 0, 0, 1},
        destination_port_no: 5001,
        local_address: {127, 0, 0, 1}
      }
    ]

    links = %{
      {:source, :output} => {:udp, :input}
    }

    spec = %Spec{children: children, links: links}
    {[spec: spec], %{}}
  end
end
```

The `UDPDemo.Receive` retrieves packets from UDP socket and
saves the data to the `/tmp/udp-recv.h264` file.

Bear in mind that for other files/sending pipelines you may need do adjust
[`recv_buffer_size`](https://hexdocs.pm/membrane_udp_plugin/Membrane.UDP.Source.html#module-element-options)
option in `Membrane.UDP.Source` that determines the maximum size of received packets.

```elixir
defmodule UDPDemo.Receive do
  use Membrane.Pipeline

  alias Membrane.Element.{File, UDP}
  alias Membrane.Pipeline.Spec

  def handle_init(_) do
    children = [
      udp: %UDP.Source{
        local_address: {127, 0, 0, 1},
        local_port_no: 5001
      },
      sink: %File.Sink{
        location: "/tmp/udp-recv.h264"
      }
    ]

    links = %{
      {:udp, :output} => {:sink, :input}
    }

    spec = %Spec{children: children, links: links}
    {[spec: spec], %{}}
  end
end
```

The snippet below presents how to run these pipelines. For convenience, it uses `Membrane.Testing.Pipeline`
that wraps the pipeline modules above and allows to assert on state changes and end of stream events from the elements.
Thanks to that, we can make sure the data is sent only when the receiving end is ready and the pipelines are stopped
after everything has been sent.

```elixir
alias Membrane.Testing.Pipeline
import Membrane.Testing.Assertions

sender = Pipeline.start_link_supervised!(%Pipeline.Options{module: UDPDemo.Send})
receiver = Pipeline.start_link_supervised!(%Pipeline.Options{module: UDPDemo.Receive})

:ok = Pipeline.play(receiver)

assert_pipeline_play(receiver)

:ok = Pipeline.play(sender)

assert_end_of_stream(sender, :udp, :input, 5000)

:ok = Pipeline.terminate(sender, blocking?: true)
:ok = Pipeline.terminate(receiver, blocking?: true)
```

The deps required to run the example:

```elixir
defp deps do
  [
    {:membrane_core, "~> 0.9.0"},
	{:membrane_udp_plugin, "~> 0.10.0"}
    {:membrane_hackney_plugin, "~> 0.6"},
    {:membrane_file_plugin, "~> 0.9"}
  ]
end
```

## Copyright and License

Copyright 2019, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

Licensed under the [Apache License, Version 2.0](LICENSE)
