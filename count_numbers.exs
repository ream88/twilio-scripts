#!/usr/bin/env elixir

Mix.install([
  {:req, "~> 0.3.4"},
  {:flow, "~> 1.2.3"}
])

Code.require_file("./lib/resources.exs")
Code.require_file("./lib/utils.exs")

defmodule CountNumbers do
  import Resources
  import Utils

  def run() do
    auth = {get_env("TWILIO_ACCOUNT_SID"), get_env("TWILIO_AUTH_TOKEN")}

    fetch_resources("accounts", "/2010-04-01/Accounts.json", auth: auth)
    |> filter_master_account()
    |> Flow.from_enumerable()
    |> Flow.reduce(fn -> 0 end, fn %{"sid" => account_sid}, acc ->
      count =
        fetch_resources(
          "incoming_phone_numbers",
          "/2010-04-01/Accounts/#{account_sid}/IncomingPhoneNumbers.json",
          auth: auth
        )
        |> Enum.count()
        |> tap(fn
          0 -> nil
          count -> IO.inspect(count, label: account_sid)
        end)

      acc + count
    end)
    |> Flow.emit(:state)
    |> Enum.sum()
    |> IO.inspect(label: "Count of active numbers")
  end
end

CountNumbers.run()
