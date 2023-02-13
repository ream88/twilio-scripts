#!/usr/bin/env elixir

Mix.install([
  {:req, "~> 0.3.4"}
])

Code.require_file("./lib/resources.exs")
Code.require_file("./lib/utils.exs")

defmodule MoveNumber do
  import Resources
  import Utils

  def run() do
    auth = {get_env("TWILIO_ACCOUNT_SID"), get_env("TWILIO_AUTH_TOKEN")}
    from_subaccount_sid = prompt("Please provide the Twilio Account SID of the source subaccount: ")
    to_subaccount_sid = prompt("Please provide the Twilio Account SID of the destination subaccount: ")
    phone_number_sid = prompt("Please provide the Phone Number SID of the phone number to move: ")

    %Req.Response{body: %{"friendly_name" => from_subaccount}} =
      fetch_resource("/2010-04-01/Accounts/#{from_subaccount_sid}.json", auth: auth)

    %Req.Response{body: %{"friendly_name" => to_subaccount}} =
      fetch_resource("/2010-04-01/Accounts/#{to_subaccount_sid}.json", auth: auth)

    %Req.Response{body: %{"phone_number" => phone_number}} =
      fetch_resource(
        "/2010-04-01/Accounts/#{from_subaccount_sid}/IncomingPhoneNumbers/#{phone_number_sid}.json",
        auth: auth
      )

    if ask("Move #{phone_number} from subaccount #{from_subaccount} to subaccount #{to_subaccount}?") do
      update_resource(
        "/2010-04-01/Accounts/#{from_subaccount_sid}/IncomingPhoneNumbers/#{phone_number_sid}.json",
        form: [AccountSid: to_subaccount_sid],
        auth: auth
      )
    else
      abort!()
    end
  end
end

MoveNumber.run()
