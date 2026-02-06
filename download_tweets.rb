# frozen_string_literal: true

require %{x}
require 'pry'
require "json"

access_tokens = JSON.parse((File.read 'access_tokens.json'), symbolize_names: true)
client = X::Client.new(**access_tokens)

begin
  user_response = client.get("users/me")
  user_id = user_response["data"]["id"]

  tweets_response = client.get("users/#{user_id}/tweets")

  binding.pry

end