defmodule Riverside.Mixfile do
  use Mix.Project

  def project do
    [
      app: :riverside,
      version: "1.2.6",
      elixir: "~> 1.5",
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [
        :cowboy,
        :logger,
        :msgpax,
        :plug,
        :poison,
        :prometheus_plugs,
        :secure_random,
        :elixir_uuid
      ]
    ]
  end

  defp deps do
    [
      {:cowboy, "~> 2.4"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:msgpax, "~> 2.0"},
      {:plug, "~> 1.7"},
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 3.1"},
      {:prometheus_plugs, "~> 1.1.5"},
      {:prometheus_ex, "~> 3.0.2"},
      {:secure_random, "~> 0.5.1"},
      {:socket, "~> 0.3.12"},
      {:the_end, "~> 1.1.0"},
      {:elixir_uuid, "~> 1.2"}
    ]
  end

  defp package() do
    [
      description: "A plain WebSocket server framework.",
      licenses: ["MIT"],
      links: %{
        "Github" => "https://github.com/lyokato/riverside",
        "Docs" => "https://hexdocs.pm/riverside/Riverside.html"
      },
      maintainers: ["Lyo Kato"]
    ]
  end
end
