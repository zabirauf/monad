defmodule Monad.Mixfile do
  use Mix.Project

  def project do
    [app: :monad,
     version: "1.0.2",
     name: "monad",
     source_url: "https://github.com/rmies/monad",
     elixir: "~> 0.13.0",
     deps: deps]
  end

  # Configuration for the OTP application
  def application do
    []
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "~> 0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [{:ex_doc, github: "elixir-lang/ex_doc"}]
  end
end
