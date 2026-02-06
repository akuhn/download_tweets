# frozen_string_literal: true

require %{json}
require %{options_by_example}
require %{pry}
require %{x}

require %(./cache)
require %(./document)


flags = OptionsByExample.read(DATA).parse ARGV

fname = flags.fetch(:argument_tokens, 'access_tokens.json')
access_tokens = JSON.parse(File.read(fname), symbolize_names: true)
client = X::Client.new(**access_tokens)

def encode(params)
  params.map { |name, value| "#{name}=#{[*value].join(?,)}" }.join(?&)
end

Dir.mkdir("data") rescue nil
media = Document.new "data/download_tweets.sqlite", 'media'
tweets = Document.new "data/download_tweets.sqlite", 'tweets'
users = Document.new "data/download_tweets.sqlite", 'users'


begin
  user_name = flags.argument_user
  user_endpoint = user_name ? "users/by/username/#{user_name}" : "users/me"
  user_id = client.get(user_endpoint)['data']['id']

  params = {
    exclude: 'replies',
    max_results: 30,
    expansions: [
      "attachments.media_keys",
      "author_id",
      "in_reply_to_user_id",
      "referenced_tweets.id",
      "referenced_tweets.id.author_id",
      "referenced_tweets.id.attachments.media_keys",
    ],
    'tweet.fields' => [
      "attachments",
      "author_id",
      "conversation_id",
      "created_at",
      "in_reply_to_user_id",
      "media_metadata",
      "note_tweet",
      "public_metrics",
      "referenced_tweets",
    ],
    'media.fields' => [
      "type",
      "url",
    ],
    'user.fields' => [
      "created_at",
      "description",
      "id",
      "location",
      "most_recent_tweet_id",
      "name",
      "pinned_tweet_id",
      "profile_image_url",
      "public_metrics",
      "url",
      "username",
      "verified",
    ],
  }

  tweets_response = client.get(endpoint = "users/#{user_id}/tweets?#{encode params}")
  tweets_response['data'].each { |each| each.delete 'edit_history_tweet_ids' }

  tweets_response['data'].each { |ea| tweets.update(ea['id'], ea) }
  tweets_response['includes']['media'].each { |ea| media.update(ea['media_key'], ea) }
  tweets_response['includes']['users'].each { |ea| users.update(ea['id'], ea) }
  tweets_response['includes']['tweets'].each { |ea| tweets.update(ea['id'], ea) }

  binding.pry if flags.include_interactive?
end


__END__
Downloads tweets into, lets say, a Sqlite data base, you know the one
hardened for use on battleships and stuff like that

Usage: download_tweets [options] [user]

Options:
  --tokens FILE           Json file with access tokens
  -i, --interactive       Opens debugger at the end of the script

