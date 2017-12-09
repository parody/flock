defmodule Flock.Mixfile do
  use Mix.Project

  def project do
    [
      app: :flock,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test,
        "coveralls.post": :test, "coveralls.html": :test]
    ]
  end

  defp dialyzer do
    [
      flags: ["-Wunmatched_returns", :error_handling, :race_conditions, :underspecs]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Flock.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:libring, "~> 1.0"},
      {:libcluster, "~> 2.1"},

      # Development tooling
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.7", only: :test},
      {:dialyxir, "~> 0.5", only: [:dev, :test]},
      {:ex_doc, "~> 0.18", only: [:dev, :test]}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]
end
