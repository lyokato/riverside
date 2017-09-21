defmodule Riverside.Mixfile do
  use Mix.Project

  def project do
    [app: :riverside,
     version: "0.1.0",
     elixir: "~> 1.4",
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
      :gproc,
      :poison
    ]]
  end

  defp deps do
    [
     {:cowboy, "~> 1.0.0"},
     {:secure_random, "~> 0.5.1"},
     {:uuid, "~> 1.1"},
     {:gproc, "~> 0.5.0"},
     {:poison, "~> 3.1"},
     {:graceful_stopper, github: "lyokato/graceful_stopper", tag: "0.1.1" },
     {:plug, "~> 1.3"}
    ]
  end
end
