#!/usr/bin/env elixir

Mix.install([
  {:req, "~> 0.3.4"},
  {:flow, "~> 1.2.3"}
])

Code.require_file("./lib/resources.exs")
Code.require_file("./lib/utils.exs")

defmodule ListSIPDomains do
  import Resources
  import Utils

  def run() do
    auth = {get_env("TWILIO_ACCOUNT_SID"), get_env("TWILIO_AUTH_TOKEN")}

    fetch_resources("accounts", "/2010-04-01/Accounts.json", auth: auth)
    |> reject_master_account()
    |> Flow.from_enumerable()
    |> Flow.reject(&(&1["status"] == "closed"))
    |> Flow.flat_map(fn %{"sid" => account_sid} ->
      fetch_resources(
        "domains",
        "/2010-04-01/Accounts/#{account_sid}/SIP/Domains.json",
        auth: auth
      )
    end)
    |> Flow.map(fn %{"sid" => sid, "account_sid" => account_sid} = properties ->
      IO.inspect(properties["voice_url"], label: "#{sid} in #{account_sid}")
    end)
    |> Flow.run()
  end
end

ListSIPDomains.run()
