defmodule Riverside.Mixfile do
  use Mix.Project

  def project do
    [app: :riverside,
     version: "0.4.1",
     elixir: "~> 1.5",
     package: package(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [
      :logger,
      :cowboy,
      :secure_random,
      :uuid,
      :plug,
      :ebus,
      :poison,
      :msgpax
      ]]
  end

  defp deps do
    [
     {:cowboy, "~> 2.2.0"},
     {:secure_random, "~> 0.5.1"},
     {:uuid, "~> 1.1"},
     {:ebus, "~> 0.2.1", hex: :erlbus},
     {:poison, "~> 3.1"},
     {:msgpax, "~> 2.0"},
     {:socket, "~> 0.3.12"},
     {:the_end, "~> 1.1.0"},
     #{:ex_doc, "~> 0.15", only: :dev, runtime: false},
     {:plug, "~> 1.5"}
    ]
  end

  defp package() do
    [
      description: "A simple WebSocket server frame work.",
      licenses: ["MIT"],
      links: %{
        "Github" => "https://github.com/lyokato/riverside"
        # "Docs" => "https://hexdocs.pm/riverside"
      },
      maintainers: ["Lyo Kato"]
    ]
  end

end
