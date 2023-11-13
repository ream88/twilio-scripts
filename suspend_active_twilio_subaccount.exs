#!/usr/bin/env elixir

Mix.install([
  {:req, "~> 0.3.4"},
  {:flow, "~> 1.2.3"}
])

Code.require_file("./lib/resources.exs")
Code.require_file("./lib/utils.exs")

defmodule SuspendActiveTwilioSubaccount do
  import Resources
  import Utils

  def run() do
    auth = {get_env("TWILIO_ACCOUNT_SID"), get_env("TWILIO_AUTH_TOKEN")}
    account_sid = prompt("Please provide the Account SID for the account you wish to suspend: ")

    update_resource("/2010-04-01/Accounts/#{account_sid}.json",
      form: [Status: "suspended"],
      auth: auth
    )
  end
end

SuspendActiveTwilioSubaccount.run()
