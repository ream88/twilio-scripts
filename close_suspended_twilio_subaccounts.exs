#!/usr/bin/env elixir

Mix.install([
  {:req, "~> 0.3.4"},
  {:flow, "~> 1.2.3"}
])

Code.require_file("./lib/resources.exs")
Code.require_file("./lib/utils.exs")

defmodule CloseSuspendedTwilioSubaccounts do
  import Resources
  import Utils

  def run() do
    auth = {get_env("TWILIO_ACCOUNT_SID"), get_env("TWILIO_AUTH_TOKEN")}

    fetch_resources("accounts", "/2010-04-01/Accounts.json", auth: auth)
    |> Flow.from_enumerable()
    |> Flow.map(fn
      %{"sid" => account_sid, "status" => "suspended"} ->
        update_resource("/2010-04-01/Accounts/#{account_sid}.json",
          form: [Status: "closed"],
          auth: auth
        )

      _ ->
        nil
    end)
    |> Flow.run()
  end
end

CloseSuspendedTwilioSubaccounts.run()
