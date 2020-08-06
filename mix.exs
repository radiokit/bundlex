defmodule Bundlex.Mixfile do
  use Mix.Project

  @version "0.3.0"

  @github_url "https://github.com/membraneframework/bundlex"

  def project do
    [
      app: :bundlex,
      version: @version,
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "Bundlex Multi-Platform build system for Elixir",
      package: package(),
      name: "Bundlex",
      source_url: @github_url,
      docs: docs(),
      preferred_cli_env: [espec: :test],
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger], mod: {Bundlex.App, []}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

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

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}",
      nest_modules_by_prefix: [Bundlex.Helper],
      groups_for_modules: [Helpers: ~r/^Bundlex\.Helper\.*/]
    ]
  end

  defp deps() do
    [
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:bunch, "~> 1.0"},
      {:qex, "~> 0.5"},
      {:secure_random, "~> 0.5"},
      {:jason, "~> 1.2"},
      {:dialyxir, "~> 1.0.0", only: [:dev], runtime: false}
    ]
  end
end
