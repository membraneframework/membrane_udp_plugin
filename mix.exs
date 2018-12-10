defmodule Membrane.Element.UDP.MixProject do
  use Mix.Project

  @version "0.2.0"
  @github_url "https://github.com/membraneframework/membrane-element-udp"

  def project do
    [
      app: :membrane_element_udp,
      version: @version,
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "Membrane Multimedia Framework (UDP Element)",
      package: package(),
      name: "Membrane Element: UDP",
      source_url: @github_url,
      docs: docs(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}"
    ]
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      }
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: [:dev, :test], runtime: false},
      {:membrane_core,
       git: "git@github.com:membraneframework/membrane-core", branch: "testing-tools"},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:mockery, "~> 2.3.0", runtime: false}
    ]
  end
end
