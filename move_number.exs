#!/usr/bin/env elixir

Mix.install([
  {:req, "~> 0.3.4"}
])

defmodule MoveNumber do
  @spec move(keyword()) :: nil
  def move(opts) do
    # Validate the keyword list
    opts =
      Keyword.validate!(opts, [
        :twilio_account_sid,
        :twilio_auth_token,
        :from_subaccount_sid,
        :to_subaccount_sid,
        :phone_number_sid
      ])

    # Extract the values from the keyword list
    twilio_account_sid = Keyword.get(opts, :twilio_account_sid)
    twilio_auth_token = Keyword.get(opts, :twilio_auth_token)
    from_subaccount_sid = Keyword.get(opts, :from_subaccount_sid)
    to_subaccount_sid = Keyword.get(opts, :to_subaccount_sid)
    phone_number_sid = Keyword.get(opts, :phone_number_sid)

    # Set up the necessary headers for the API request
    headers = [
      {"Authorization", "Basic #{Base.encode64("#{twilio_account_sid}:#{twilio_auth_token}")}"},
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    {:ok, %Req.Response{status: 200, body: from_subaccount}} =
      Req.get(
        "https://api.twilio.com/2010-04-01/Accounts/#{from_subaccount_sid}.json",
        headers: headers
      )

    {:ok, %Req.Response{status: 200, body: to_subaccount}} =
      Req.get(
        "https://api.twilio.com/2010-04-01/Accounts/#{to_subaccount_sid}.json",
        headers: headers
      )

    {:ok, %Req.Response{status: 200, body: phone_number}} =
      Req.get(
        "https://api.twilio.com/2010-04-01/Accounts/#{from_subaccount_sid}/IncomingPhoneNumbers/#{phone_number_sid}.json",
        headers: headers
      )

    "This will move #{Map.fetch!(phone_number, "phone_number")} from subaccount #{Map.fetch!(from_subaccount, "friendly_name")} to subaccount #{Map.fetch!(to_subaccount, "friendly_name")}! Proceed? [y/N]"
    |> prompt()
    |> String.downcase()
    |> case do
      "y" ->
        # Send the API request to move the phone number
        Req.post!(
          "https://api.twilio.com/2010-04-01/Accounts/#{from_subaccount_sid}/IncomingPhoneNumbers/#{phone_number_sid}.json",
          headers: headers,
          body: "AccountSid=#{to_subaccount_sid}"
        )

      _ ->
        IO.puts("Aborted!")
    end
  end

  def prompt(question) do
    case IO.gets("#{question}: ") do
      string when is_binary(string) -> String.trim(string)
      _ -> ""
    end
  end
end

MoveNumber.move(
  twilio_account_sid:
    MoveNumber.prompt("Please provide the Twilio Account SID of the master account"),
  twilio_auth_token:
    MoveNumber.prompt("Please provide the Twilio Auth Token of the master account"),
  from_subaccount_sid:
    MoveNumber.prompt("Please provide the Twilio Account SID of the source subaccount"),
  to_subaccount_sid:
    MoveNumber.prompt("Please provide the Twilio Account SID of the destination subaccount"),
  phone_number_sid:
    MoveNumber.prompt("Please provide the Phone Number SID of the phone number to move")
)
