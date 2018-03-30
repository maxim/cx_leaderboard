defmodule CxLeaderboard.MixProject do
  use Mix.Project

  def project do
    [
      description: "Fast, customizable leaderboards database.",
      app: :cx_leaderboard,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      source_url: "https://github.com/crossfield/cx_leaderboard",
      dialyzer: [flags: ["-Wunmatched_returns", :error_handling, :underspecs]],
      docs: [main: "CxLeaderboard.Leaderboard", extras: ["README.md"]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    %{
      licenses: ["Apache 2"],
      maintainers: ["Max Chernyak"],
      links: %{"GitHub" => "https://github.com/crossfield/cx_leaderboard"},
      files:
        ~w(lib .formatter.exs CODE_OF_CONDUCT.md LICENSE mix.exs README.md)
    }
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:benchee, "~> 0.12", only: :dev, runtime: false},
      {:ex_doc, "~> 0.18", only: :dev, runtime: false}
    ]
  end
end
