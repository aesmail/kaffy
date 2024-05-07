defmodule Kaffy.MixProject do
  use Mix.Project

  @source_url "https://github.com/aesmail/kaffy"
  @version "0.10.2"

  def project do
    [
      app: :kaffy,
      aliases: aliases(),
      version: @version,
      elixir: "~> 1.12",
      compilers: Mix.compilers(),
      elixirc_paths: elixirc_paths(Mix.env()),
      preferred_cli_env: [
        "test.reset": :test,
        "test.setup": :test,
        "ecto.gen.migration": :test
      ],
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
  defp elixirc_paths(:test), do: ["lib", "test/fixtures", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_machina, "~> 2.7.0", only: :test},
      {:phoenix, "~> 1.7.10"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_view, "~> 2.0.2"},
      {:mock, "~> 0.3.3", only: :test},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.10"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:jason, "~> 1.3", only: :test},
      {:postgrex, "~> 0.16", optional: true}
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

  defp aliases do
    [
      "test.reset": ["ecto.drop", "test.setup"],
      "test.setup": ["ecto.create", "ecto.migrate"]
    ]
  end
end
