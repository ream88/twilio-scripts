#!/usr/bin/env elixir

Mix.install([
  {:req, "~> 0.3.4"}
])

Code.require_file("./lib/utils.exs")

defmodule UpdatePhoneNumberToUseTwimlApp do
  import Utils

  def run() do
    account_sid = get_env("TWILIO_ACCOUNT_SID")
    auth = {account_sid, get_env("TWILIO_AUTH_TOKEN")}
    application_sid = get_env("TWILIO_APPLICATION_SID")
    phone_number_sid = prompt("Please provide the ID of your phone number: ")

    url = "https://api.twilio.com/2010-04-01/Accounts/#{account_sid}/IncomingPhoneNumbers/#{phone_number_sid}.json"

    Req.post!(url,
      form: [
        VoiceApplicationSid: application_sid,
        VoiceUrl: "",
        VoiceFallbackUrl: "",
        StatusCallback: ""
      ],
      auth: auth
    )
  end
end

UpdatePhoneNumberToUseTwimlApp.run()
