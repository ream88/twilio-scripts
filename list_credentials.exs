#!/usr/bin/env elixir

Mix.install([
  {:req, "~> 0.3.4"},
  {:flow, "~> 1.2.3"}
])

Code.require_file("./lib/resources.exs")
Code.require_file("./lib/utils.exs")

defmodule ListCredentials do
  import Resources
  import Utils

  def run() do
    auth = {get_env("TWILIO_ACCOUNT_SID"), get_env("TWILIO_AUTH_TOKEN")}

    fetch_resources("accounts", "/2010-04-01/Accounts.json", auth: auth)
    |> filter_master_account()
    |> Flow.from_enumerable()
    |> Flow.reject(&(&1["status"] == "closed"))
    |> Flow.map(fn %{"sid" => account_sid, "auth_token" => auth_token} ->
      fetch_resources(
        "credentials",
        "/Credentials",
        base_url: "https://notify.twilio.com/v1",
        auth: {account_sid, auth_token}
      )
      |> Enum.map(&Map.get(&1, "sid"))
      |> IO.inspect(label: account_sid)
    end)
    |> Flow.run()
  end
end

ListCredentials.run()
