defmodule Membrane.UDP.MixProject do
  use Mix.Project

  @version "0.9.1"
  @github_url "https://github.com/membraneframework/membrane_udp_plugin"

  def project do
    [
      app: :membrane_udp_plugin,
      version: @version,
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "Membrane UDP plugin",
      package: package(),
      name: "Membrane UDP plugin",
      source_url: @github_url,
      docs: docs(),
      deps: deps(),
      dialyzer: dialyzer()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp docs do
    [
      main: "readme",
      extras: ["README.md", LICENSE: [title: "License"]],
      formatters: ["html"],
      source_ref: "v#{@version}",
      nest_modules_by_prefix: [Membrane.UDP]
    ]
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membrane.stream"
      }
    ]
  end

  defp deps do
    [
      {:membrane_core, "~> 0.11.0"},
      {:mockery, "~> 2.3.0", runtime: false},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:credo, "~> 1.5", only: :dev, runtime: false}
    ]
  end

  defp dialyzer() do
    opts = [
      flags: [:error_handling]
    ]

    if System.get_env("CI") == "true" do
      # Store PLTs in cacheable directory for CI
      [plt_local_path: "priv/plts", plt_core_path: "priv/plts"] ++ opts
    else
      opts
    end
  end
end
