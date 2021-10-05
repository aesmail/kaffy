defmodule Kaffy.MixProject do
  use Mix.Project

  @version "0.9.1"

  def project do
    [
      app: :kaffy,
      version: @version,
      elixir: "~> 1.8",
      compilers: [:phoenix] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      name: "Kaffy",
      source_url: "https://github.com/aesmail/kaffy",
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Kaffy.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.4"},
      {:phoenix_html, "~> 2.13 or ~> 3.0"},
      {:mock, "~> 0.3.0", only: :test},
      {:ecto, "~> 3.5"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "Powerfully simple admin package for phoenix applications"
  end

  defp package() do
    [
      maintainers: ["Abdullah Esmail"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/aesmail/kaffy",
        "Demo" => "https://kaffy.gigalixirapp.com/admin/"
      }
    ]
  end

  def docs() do
    [
      main: "readme",
      name: "Kaffy",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/kaffy",
      source_url: "https://github.com/aesmail/kaffy",
      extras: [
        "README.md"
      ]
    ]
  end
end
