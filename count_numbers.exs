Mix.install([
  {:req, "~> 0.3.4"},
  {:flow, "~> 1.2.3"}
])

defmodule CountNumbers do
  def run() do
    auth = {get_env("TWILIO_ACCOUNT_SID"), get_env("TWILIO_AUTH_TOKEN")}

    fetch_resource("accounts", "/2010-04-01/Accounts.json", auth: auth)
    |> Flow.from_enumerable()
    |> Flow.reduce(fn -> 0 end, fn %{"sid" => account_sid}, acc ->
      count =
        fetch_resource(
          "incoming_phone_numbers",
          "/2010-04-01/Accounts/#{account_sid}/IncomingPhoneNumbers.json",
          auth: auth
        )
        |> Enum.count()
        |> tap(fn
          0 -> nil
          count -> IO.inspect(count, label: account_sid)
        end)

      acc + count
    end)
    |> Flow.emit(:state)
    |> Enum.sum()
    |> IO.inspect(label: "Count of active numbers")
  end

  defp fetch_resource(name, uri, opts) do
    fetch_resource([], name, uri, opts)
  end

  defp fetch_resource(resources, _name, nil, _opts) do
    resources
  end

  defp fetch_resource(rest, name, uri, opts) do
    %{body: %{^name => resources, "next_page_uri" => uri}} =
      Req.get!("https://api.twilio.com" <> uri, opts)

    fetch_resource(rest ++ resources, name, uri, opts)
  end

  defp get_env(name) do
    case System.get_env(name) do
      nil -> prompt("Please provide a value for #{name}: ")
      value -> value
    end
  end

  defp prompt(message) do
    message |> IO.gets() |> String.trim()
  end
end

CountNumbers.run()
