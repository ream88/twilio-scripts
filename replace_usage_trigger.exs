#!/usr/bin/env elixir

Mix.install([
  {:req, "~> 0.3.4"},
  {:flow, "~> 1.2.3"}
])

Code.require_file("./lib/resources.exs")
Code.require_file("./lib/utils.exs")

defmodule ReplaceUsageTrigger do
  import Resources
  import Utils

  def run() do
    auth = {get_env("TWILIO_ACCOUNT_SID"), get_env("TWILIO_AUTH_TOKEN")}
    callback_url = get_env("CB_CALLBACK_URL")
    recurring = get_env("CB_RECURRING")
    trigger_by = get_env("CB_TRIGGER_BY")
    trigger_value = get_env("CB_TRIGGER_VALUE")
    usage_category = get_env("CB_USAGE_CATEGORY")

    account_sid = get_env("TWILIO_ACCOUNT_SID")

    fetch_resources(
      "usage_triggers",
      "/2010-04-01/Accounts/#{account_sid}/Usage/Triggers.json",
      auth: auth
    )
    |> Enum.each(fn %{"sid" => usage_trigger_sid, "account_sid" => account_sid} ->
      delete_resource("/2010-04-01/Accounts/#{account_sid}/Usage/Triggers/#{usage_trigger_sid}.json", auth: auth)
    end)

    create_resource("/2010-04-01/Accounts/#{account_sid}/Usage/Triggers.json",
      form: [
        CallbackMethod: "POST",
        CallbackUrl: callback_url <> "?sub_account_sid=" <> account_sid,
        FriendlyName: "Circuit Breaker",
        Recurring: recurring,
        TriggerBy: trigger_by,
        TriggerValue: trigger_value,
        UsageCategory: usage_category
      ],
      auth: auth
    )
  end
end

ReplaceUsageTrigger.run()
