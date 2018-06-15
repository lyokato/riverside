defmodule Riverside.Mixfile do
  use Mix.Project

  def project do
    [app: :riverside,
     version: "1.0.6",
     elixir: "~> 1.5",
     package: package(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [
      :cowboy,
      :ebus,
      :logger,
      :msgpax,
      :plug,
      :poison,
      :prometheus_plugs,
      :secure_random,
      :uuid
      ]]
  end

  defp deps do
    [
     {:cowboy, "~> 2.2"},
     {:ebus, "~> 0.2.1", hex: :erlbus},
     {:ex_doc, "~> 0.15", only: :dev, runtime: false},
     {:msgpax, "~> 2.0"},
     {:plug, "~> 1.5"},
     {:poison, "~> 3.1"},
     {:prometheus_plugs, "~> 1.1.1"},
     {:secure_random, "~> 0.5.1"},
     {:socket, "~> 0.3.12"},
     {:the_end, "~> 1.1.0"},
     {:uuid, "~> 1.1"}
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
