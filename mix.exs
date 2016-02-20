defmodule Posterize.Mixfile do
  use Mix.Project

  @version "0.9.2"

  def project do
    [app: :posterize,
     version: @version,
     elixir: "~> 1.0",
     deps: deps,
     name: "posterize",
     source_url: "https://github.com/talentdefict/posterize",
     docs: [source_ref: "v#{@version}", main: "readme", extras: ["README.md"]],
     description: description,
     package: package]
  end

  def application do
    [applications: [:postgrex]]
  end

  defp deps do
    [{:postgrex, "~> 0.11.0"},
     {:jsx, "~> 2.8"},
     {:ex_doc, "~> 0.11", only: :dev},
     {:earmark, "~> 0.1", only: :dev},
     {:sbroker, "~> 0.7.0", only: :dev},
     {:poolboy, "~> 1.5.1", only: :dev}]
  end

  defp description do
    "erlang wrapper for postgrex"
  end

  defp package do
    [maintainers: ["alisdair sullivan"],
     licenses: ["Apache 2.0", "MIT"],
     links: %{"Github" => "https://github.com/talentdeficit/posterize"}]
  end
end