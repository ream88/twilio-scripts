#!/usr/bin/env elixir

Mix.install([
  {:req, "~> 0.3.4"},
  {:flow, "~> 1.2.3"}
])

Code.require_file("./lib/resources.exs")
Code.require_file("./lib/utils.exs")

defmodule ListNumbers do
  import Resources
  import Utils

  def run() do
    auth = {get_env("TWILIO_ACCOUNT_SID"), get_env("TWILIO_AUTH_TOKEN")}

    fetch_resources("accounts", "/2010-04-01/Accounts.json", auth: auth)
    |> Flow.from_enumerable()
    |> Flow.flat_map(fn %{"sid" => account_sid} ->
      fetch_resources(
        "incoming_phone_numbers",
        "/2010-04-01/Accounts/#{account_sid}/IncomingPhoneNumbers.json",
        auth: auth
      )
    end)
    |> Flow.map(fn %{"sid" => phone_number_sid, "account_sid" => account_sid} = properties ->
      IO.inspect(properties["voice_application_sid"], label: "#{phone_number_sid} in #{account_sid}")
    end)
    |> Flow.run()
  end
end

ListNumbers.run()
