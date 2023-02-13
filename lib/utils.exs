defmodule Utils do
  def get_env(name) do
    case System.get_env(name) do
      nil -> prompt("Please provide a value for #{name}: ")
      value -> value
    end
  end

  def prompt(message) do
    message |> IO.gets() |> String.trim()
  end

  def ask(message) do
    (message <> " [y/N] ")
    |> prompt()
    |> String.downcase() ==
      "y"
  end
end