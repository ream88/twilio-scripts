#!/usr/bin/env elixir

Mix.install([
  {:req, "~> 0.3.4"},
  {:flow, "~> 1.2.3"},
  {:postgrex, "~> 0.17.1"}
])

Logger.configure(level: :warn)

Code.require_file("./lib/custom_cache.exs")
Code.require_file("./lib/resources.exs")
Code.require_file("./lib/utils.exs")

defmodule GenerateTwilioCallPricesTable do
  import Resources
  import Utils

  @from_eea [
    "30",
    "31",
    "32",
    "33",
    "34",
    "351",
    "352",
    "353",
    "354",
    "356",
    "357",
    "358",
    "359",
    "36",
    "370",
    "371",
    "372",
    "385",
    "386",
    "39",
    "40",
    "420",
    "421",
    "423",
    "43",
    "44",
    "45",
    "46",
    "47",
    "48",
    "49"
  ]

  def run do
    opts = [
      auth: {get_env("TWILIO_ACCOUNT_SID"), get_env("TWILIO_AUTH_TOKEN")},
      base_url: "https://pricing.twilio.com",
      custom_cache_dir: Path.expand("./cache", __DIR__)
    ]

    fetch_resources("countries", "/v2/Voice/Countries", opts)
    |> Flow.from_enumerable()
    |> Flow.map(fn %{"url" => url} ->
      fetch_country(url, opts).body
    end)
    |> Flow.flat_map(fn %{"iso_country" => country, "outbound_prefix_prices" => prices} ->
      Enum.flat_map(prices, fn %{
                                 "friendly_name" => destination,
                                 "base_price" => base_price,
                                 "origination_prefixes" => origination_prefixes,
                                 "destination_prefixes" => destination_prefixes
                               } ->
        from_eea = origination_prefixes == @from_eea
        price = String.to_float(base_price) * 1.15
        price_in_credits = Float.ceil(price * 100)

        Enum.map(destination_prefixes, fn prefix ->
          [country, destination, from_eea, price, price_in_credits, price_in_credits, "+" <> prefix]
        end)
      end)
    end)
    |> Flow.map(fn [
                     country,
                     destination,
                     from_eea,
                     price,
                     price_in_cents,
                     price_in_credits,
                     prefix
                   ] ->
      from_eea =
        case from_eea do
          true -> 1
          false -> 0
        end

      """
      INSERT INTO twilio_call_prices(country, destination, from_eea, price, price_in_cents, price_in_credits, prefix, organization_id)
        VALUES (E'#{country}', $$#{destination}$$, #{from_eea}, #{price}, #{price_in_cents}, #{price_in_credits}, E'#{prefix}', NULL);
      """
    end)
    |> Flow.stream()
    |> Stream.into(File.stream!("twilio-call-prices.sql", [:write, :utf8]))
    |> Stream.run()
  end

  defp fetch_country(url, opts) do
    Req.new(url: url)
    |> CustomCache.attach(opts)
    |> Req.get!()
  end
end

GenerateTwilioCallPricesTable.run()
