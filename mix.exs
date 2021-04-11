defmodule Frank.MixProject do
  use Mix.Project

  def project do
    [
      app: :frank,
      version: File.read!("VERSION") |> String.trim(),
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Frank.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:atomic_map, "~> 0.8"},
      {:cors_plug, "~> 2.0"},
      {:earmark, "~> 1.4"},
      {:floki, "~> 0.23.0"},
      {:plug, "~> 1.8"},
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 3.1"},
      {:poolboy, "~> 1.5.2"}
    ]
  end
end
