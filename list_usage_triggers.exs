#!/usr/bin/env elixir

Mix.install([
  {:req, "~> 0.3.4"},
  {:flow, "~> 1.2.3"}
])

Code.require_file("./lib/resources.exs")
Code.require_file("./lib/utils.exs")

defmodule ListUsageTriggers do
  import Resources
  import Utils

  def run() do
    auth = {get_env("TWILIO_ACCOUNT_SID"), get_env("TWILIO_AUTH_TOKEN")}

    fetch_resources("accounts", "/2010-04-01/Accounts.json", auth: auth)
    |> filter_master_account()
    |> Flow.from_enumerable()
    |> Flow.reject(&(&1["status"] == "closed"))
    |> Flow.map(fn %{"sid" => account_sid} ->
      case fetch_resources(
             "usage_triggers",
             "/2010-04-01/Accounts/#{account_sid}/Usage/Triggers.json",
             auth: auth
           ) do
        [] ->
          IO.puts(account_sid <> ": " <> IO.ANSI.red() <> "No triggers found!" <> IO.ANSI.reset())

        usage_triggers ->
          Enum.each(usage_triggers, fn usage_trigger ->
            usage_trigger
            |> Map.take(["usage_category", "trigger_by", "trigger_value", "current_value", "callback_url"])
            |> IO.inspect(label: account_sid)
          end)
      end
    end)
    |> Flow.run()
  end
end

ListUsageTriggers.run()
