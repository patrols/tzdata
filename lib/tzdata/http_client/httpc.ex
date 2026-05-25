defmodule Tzdata.HTTPClient.Httpc do
  @moduledoc false

  @behaviour Tzdata.HTTPClient

  @impl true
  def get(url, headers, options) do
    case request(:get, url, headers, options) do
      {:ok, {status, resp_headers, body}} ->
        {:ok, {status, resp_headers, body}}

      {:error, _} = err ->
        err
    end
  end

  @impl true
  def head(url, headers, options) do
    case request(:head, url, headers, options) do
      {:ok, {status, resp_headers, _body}} ->
        {:ok, {status, resp_headers}}

      {:error, _} = err ->
        err
    end
  end

  defp request(method, url, headers, options) do
    http_options = [
      autoredirect: Keyword.get(options, :follow_redirect, false),
      ssl: ssl_options(url)
    ]

    request_arg =
      {to_charlist(url),
       Enum.map(headers, fn {k, v} -> {to_charlist(k), to_charlist(v)} end)}

    case :httpc.request(method, request_arg, http_options, body_format: :binary) do
      {:ok, {{_http_version, status, _reason}, resp_headers, body}} ->
        decoded_headers =
          Enum.map(resp_headers, fn {k, v} -> {to_string(k), to_string(v)} end)

        {:ok, {status, decoded_headers, body}}

      {:error, _reason} = err ->
        err
    end
  end

  defp ssl_options(url) do
    case URI.parse(url) do
      %URI{scheme: "https", host: host} when is_binary(host) ->
        [
          verify: :verify_peer,
          cacerts: :public_key.cacerts_get(),
          server_name_indication: to_charlist(host),
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ],
          depth: 3
        ]

      _ ->
        []
    end
  end
end
