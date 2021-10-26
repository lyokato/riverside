defmodule Riverside.Mixfile do
  use Mix.Project

  def project do
    [
      app: :riverside,
      version: "1.2.6",
      elixir: "~> 1.11",
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
        :secure_random,
        :elixir_uuid
      ]
    ]
  end

  defp deps do
    [
      {:cowboy, "~> 2.9"},
      {:ex_doc, "~> 0.25", only: :dev, runtime: false},
      {:msgpax, "~> 2.3"},
      {:plug, "~> 1.12"},
      {:plug_cowboy, "~> 2.5"},
      {:poison, "~> 5.0"},
      {:secure_random, "~> 0.5"},
      {:socket, "~> 0.3"},
      {:the_end, "~> 1.1"},
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
