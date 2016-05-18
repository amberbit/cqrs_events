defmodule Cqrs.Events.Mixfile do
  use Mix.Project

  def project do
    [app: :cqrs_events,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :moebius, :gproc], # replace phoenix with phoenix_pubsub when released
     mod: {Cqrs.Events, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:moebius, "~> 2.0.0"},
      {:poison, "~> 2.1.0", override: true },
      {:gproc, "~> 0.5.0"},
    ]
  end
end
