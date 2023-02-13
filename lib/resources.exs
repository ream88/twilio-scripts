defmodule Resources do
  @base_uri "https://api.twilio.com"

  def fetch_resources(name, uri, opts) do
    fetch_resources([], name, uri, opts)
  end

  def fetch_resources(resources, _name, nil, _opts) do
    resources
  end

  def fetch_resources(rest, name, uri, opts) do
    %{body: %{^name => resources, "next_page_uri" => uri}} = Req.get!(@base_uri <> uri, opts)
    fetch_resources(rest ++ resources, name, uri, opts)
  end

  def fetch_resource(uri, opts) do
    Req.get!(@base_uri <> uri, opts)
  end

  def update_resource(uri, opts) do
    Req.post!(@base_uri <> uri, opts)
  end
end
