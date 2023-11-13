#!/usr/bin/env elixir

Mix.install([
  {:req, "~> 0.3.4"}
])

Code.require_file("./lib/resources.exs")
Code.require_file("./lib/utils.exs")

defmodule ListSubaccounts do
  import Resources
  import Utils

  def run() do
    auth = {get_env("TWILIO_ACCOUNT_SID"), get_env("TWILIO_AUTH_TOKEN")}

    fetch_resources("accounts", "/2010-04-01/Accounts.json", auth: auth)
    |> reject_master_account()
    |> Enum.map(fn %{"sid" => account_sid} = attrs ->
      IO.inspect(attrs, label: account_sid)
    end)
  end
end

ListSubaccounts.run()
