defmodule Membrane.Element.UDP.Mixfile do
  use Mix.Project

  def project do
    [app: :membrane_element_udp,
     version: "0.0.1",
     elixir: "~> 1.3",
     elixirc_paths: elixirc_paths(Mix.env),
     description: "Membrane Multimedia Framework (UDP Element)",
     maintainers: ["Mateusz Nowak"],
     licenses: ["LGPL"],
     name: "Membrane Element: UDP",
     source_url: "https://github.com/membraneframework/membrane-element-udp",
     preferred_cli_env: [espec: :test],
     deps: deps()]
  end


  def application do
    [applications: [
      :membrane_core
    ], mod: {Membrane.Element.UDP, []}]
  end


  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib",]


  defp deps do
    [
      {:membrane_core, git: "git@github.com:membraneframework/membrane-core.git", branch: "v0.1"},
      {:espec, "~> 1.1.2", only: :test},
    ]
  end
end
