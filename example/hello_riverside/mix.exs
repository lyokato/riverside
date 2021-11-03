defmodule HelloRiverside.MixProject do
  use Mix.Project

  def project do
    [
      app: :hello_riverside,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {HelloRiverside.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:riverside, path: "../.."}
    ]
  end
end
