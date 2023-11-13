#!/usr/bin/env elixir

Mix.install([
  {:req, "~> 0.3.4"}
])

Code.require_file("./lib/utils.exs")

defmodule ShowPhoneNumber do
  import Utils

  def run() do
    account_sid = get_env("TWILIO_ACCOUNT_SID")
    auth = {account_sid, get_env("TWILIO_AUTH_TOKEN")}
    phone_number_sid = prompt("Please provide the ID of your phone number: ")

    url = "https://api.twilio.com/2010-04-01/Accounts/#{account_sid}/IncomingPhoneNumbers/#{phone_number_sid}.json"

    %Req.Response{body: body} = Req.get!(url, auth: auth)
    IO.inspect(body)
  end
end

ShowPhoneNumber.run()
