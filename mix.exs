defmodule Posterize.Mixfile do
  use Mix.Project

  @version "0.13.0"

  def project do
    [app: :posterize,
     version: @version,
     elixir: "~> 1.0",
     deps: deps(),
     name: "posterize",
     source_url: "https://github.com/talentdefict/posterize",
     docs: [source_ref: "v#{@version}", main: "readme", extras: ["README.md"]],
     description: description(),
     package: package()]
  end

  def application do
    [applications: [:postgrex, :sbroker]]
  end

  defp deps do
    [{:postgrex, "~> 0.13.0"},
     {:sbroker, "~> 1.0.0"},
     {:ex_doc, "~> 0.12", only: :dev}]
  end

  defp description do
    "erlang wrapper for the postgrex postgres client"
  end

  defp package do
    [maintainers: ["alisdair sullivan"],
     licenses: ["Apache 2.0", "MIT"],
     links: %{"Github" => "https://github.com/talentdeficit/posterize"}]
  end
end
