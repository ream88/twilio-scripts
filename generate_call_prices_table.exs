#!/usr/bin/env elixir

Mix.install([
  {:flow, "~> 1.2.3"},
  {:nimble_csv, "~> 1.2.0"},
  {:req, "~> 0.3.4"}
])

Logger.configure(level: :warning)

Code.require_file("./lib/custom_cache.exs")
Code.require_file("./lib/resources.exs")
Code.require_file("./lib/utils.exs")

defmodule GenerateTwilioCallPricesTable do
  NimbleCSV.define(CSV, [])

  import Resources
  import Utils

  def generate_sql do
    fetch_prices()
    |> Flow.stream()
    |> Stream.map(fn [name, country_code, origination_prefix, destination_prefix, price] ->
      comment = "Inserted automatically"

      if origination_prefix do
        """
        INSERT INTO call_prices(country_code, name, price, origination_prefix, destination_prefix, comment)
          VALUES ($$#{country_code}$$, $$#{name}$$, #{price}, $$#{origination_prefix}$$, $$#{destination_prefix}$$, $$#{comment}$$)
        ON CONFLICT (country_code, origination_prefix, destination_prefix)
        WHERE
          organization_id IS NULL
            DO UPDATE
              SET price = EXCLUDED.price, updated_at = NOW(), comment = $$Inserted automatically, changed from $$ || call_prices.price || $$ to $$ || EXCLUDED.price
            WHERE
              call_prices.price IS DISTINCT FROM EXCLUDED.price;
        """
      else
        """
        INSERT INTO call_prices(country_code, name, price, destination_prefix, comment)
          VALUES ($$#{country_code}$$, $$#{name}$$, #{price}, $$#{destination_prefix}$$, $$#{comment}$$)
        ON CONFLICT (country_code, destination_prefix)
        WHERE
          organization_id IS NULL AND origination_prefix IS NULL
            DO UPDATE
              SET price = EXCLUDED.price, updated_at = NOW(), comment = $$Inserted automatically, changed from $$ || call_prices.price || $$ to $$ || EXCLUDED.price
            WHERE
              call_prices.price IS DISTINCT FROM EXCLUDED.price;
        """
      end
    end)
    |> Stream.into(File.stream!("call_prices.sql", [:write, :utf8]))
    |> Stream.run()
  end

  def generate_csv do
    fetch_prices()
    |> CSV.dump_to_stream()
    |> Stream.into(File.stream!("call_prices.csv", [:write, :utf8]))
    |> Stream.run()
  end

  defp fetch_prices do
    opts = [
      auth: {get_env("TWILIO_ACCOUNT_SID"), get_env("TWILIO_AUTH_TOKEN")},
      base_url: "https://pricing.twilio.com",
      custom_cache_dir: Path.expand("./cache", __DIR__)
    ]

    fetch_resources("countries", "/v2/Voice/Countries", opts)
    |> Flow.from_enumerable()
    |> Flow.map(fn %{"url" => url} -> fetch_country(url, opts).body end)
    |> Flow.flat_map(fn %{"iso_country" => country_code, "outbound_prefix_prices" => prices} ->
      Enum.flat_map(prices, fn %{
                                 "friendly_name" => name,
                                 "base_price" => base_price,
                                 "origination_prefixes" => origination_prefixes,
                                 "destination_prefixes" => destination_prefixes
                               } ->
        price =
          base_price
          |> String.to_float()
          # 15% uptick
          |> then(&(&1 * 1.15))
          # Convert into cents
          |> then(&(&1 * 100))
          |> Float.ceil()

        for origination_prefix <- origination_prefixes, destination_prefix <- destination_prefixes do
          if Regex.match?(~R/^\d+$/, origination_prefix) do
            [name, country_code, "+" <> origination_prefix, "+" <> destination_prefix, price]
          else
            [name, country_code, nil, "+" <> destination_prefix, price]
          end
        end
      end)
    end)
  end

  defp fetch_country(url, opts) do
    Req.new(url: url)
    |> CustomCache.attach(opts)
    |> Req.get!()
  end
end

GenerateTwilioCallPricesTable.generate_sql()
GenerateTwilioCallPricesTable.generate_csv()
