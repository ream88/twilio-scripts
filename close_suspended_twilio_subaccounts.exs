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

    unless ask("This will close all suspended subaccounts. #{red("This can't be undone!")} Continue?") do
      abort!()
    end

    fetch_resources("accounts", "/2010-04-01/Accounts.json", auth: auth)
    |> reject_master_account()
    |> Flow.from_enumerable()
    |> Flow.filter(&(&1["status"] == "suspended"))
    |> Flow.map(fn
      %{"sid" => account_sid} ->
        update_resource("/2010-04-01/Accounts/#{account_sid}.json",
          form: [Status: "closed"],
          auth: auth
        )
    end)
    |> Flow.run()
  end
end

CloseSuspendedTwilioSubaccounts.run()
