# Membrane UDP plugin

[![Hex.pm](https://img.shields.io/hexpm/v/membrane_udp_plugin.svg)](https://hex.pm/packages/membrane_udp_plugin)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_udp_plugin/)
[![CircleCI](https://circleci.com/gh/membraneframework/membrane_udp_plugin.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane_udp_plugin)

This package provides UDP Source and Sink, that read and write to UDP sockets.

## Installation

Add the following line to your `deps` in `mix.exs`. Run `mix deps.get`.

```elixir
	{:membrane_udp_plugin, "~> 0.13.0"}
```

## Usage example

The `example/` shows 2 pipelines. 

The `UDPDemo.Send` downloads an example file over HTTP and sends it over UDP socket via localhost:
```bash
$ elixir examples/sink.exs
```

The `UDPDemo.Receive` retrieves packets from UDP socket and saves the data to the `/tmp/udp-recv.mp4` file.
```bash
$ elixir examples/source.exs
```

Bear in mind that for other files/sending pipelines you may need do adjust
[`recv_buffer_size`](https://hexdocs.pm/membrane_udp_plugin/Membrane.UDP.Source.html#module-element-options)
option in `Membrane.UDP.Source` that determines the maximum size of received packets.

## Copyright and License

Copyright 2024, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

Licensed under the [Apache License, Version 2.0](LICENSE)
