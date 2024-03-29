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

  def run([]) do
    auth = {get_env("TWILIO_ACCOUNT_SID"), get_env("TWILIO_AUTH_TOKEN")}

    fetch_resources("accounts", "/2010-04-01/Accounts.json", auth: auth)
    |> reject_master_account()
    |> Enum.reject(&(&1["status"] == "closed"))
    |> Enum.map(& &1["sid"])
    |> run()
  end

  def run(account_sids) do
    auth = {get_env("TWILIO_ACCOUNT_SID"), get_env("TWILIO_AUTH_TOKEN")}

    account_sids
    |> Flow.from_enumerable()
    |> Flow.map(fn account_sid ->
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
            |> Map.take([
              "usage_category",
              "trigger_by",
              "trigger_value",
              "current_value",
              "callback_url",
              "recurring"
            ])
            |> IO.inspect(label: account_sid)
          end)
      end
    end)
    |> Flow.run()
  end
end

ListUsageTriggers.run(System.argv())
