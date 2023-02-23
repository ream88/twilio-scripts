defmodule Resources do
  @base_url "https://api.twilio.com"

  def fetch_resources(name, uri, opts) do
    fetch_resources([], name, uri, opts)
  end

  def fetch_resources(resources, _name, nil, _opts) do
    resources
  end

  def fetch_resources(rest, name, uri, opts) do
    case Req.get!(base_url(opts) <> uri, opts) do
      %{body: %{^name => resources, "next_page_uri" => uri}} ->
        fetch_resources(rest ++ resources, name, uri, opts)

      %{body: %{^name => resources, "meta" => %{"next_page_url" => nil}}} ->
        fetch_resources(rest ++ resources, name, nil, opts)

      %{body: %{^name => resources, "meta" => %{"next_page_url" => url}}} ->
        %{path: uri} = URI.parse(url)
        fetch_resources(rest ++ resources, name, uri, opts)
    end
  end

  def fetch_resource(uri, opts) do
    Req.get!(base_url(opts) <> uri, opts)
  end

  def update_resource(uri, opts) do
    Req.post!(base_url(opts) <> uri, opts)
  end

  defp base_url(opts) do
    Keyword.get(opts, :base_url, @base_url)
  end
end
