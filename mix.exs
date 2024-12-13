defmodule Kaffy.MixProject do
  use Mix.Project

  @source_url "https://github.com/aesmail/kaffy"
  @version "0.10.3"

  def project do
    [
      app: :kaffy,
      version: @version,
      elixir: "~> 1.12",
      compilers: Mix.compilers(),
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      name: "Kaffy",
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

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/fixtures"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.7.10"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_view, "~> 2.0.2"},
      {:mock, "~> 0.3.3", only: :test},
      {:ecto, "~> 3.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:jason, "~> 1.3", only: :test},
      {:decimal, "~> 2.2", optional: true}
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
        "GitHub" => @source_url,
        "Demo" => "https://kaffy.fly.dev/admin/",
        "Sponsor" => "https://github.com/sponsors/aesmail"
      }
    ]
  end

  def docs() do
    [
      extras: [
        "CHANGELOG.md": [],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      assets: "assets",
      source_url: @source_url,
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/kaffy",
      formatters: ["html"]
    ]
  end
end
