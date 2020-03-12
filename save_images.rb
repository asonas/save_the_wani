require 'twitter'
require 'pp'
require 'pry'

client = Twitter::REST::Client.new do |config|
  config.consumer_key    = ENV['TWITTER_API_KEY']
  config.consumer_secret = ENV['TWITTER_API_SECRET']
  config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
  config.access_token_secret = ENV['TWITTER_ACCESS_SECRET']
end


class SaveTheWani
  AUTHOR = "yuukikikuchi"

  def initialize
    @collection = []
  end

  def self.run
    new.search
  end

  def search
    client.user_timeline(AUTHOR, count:300).take(1).each do |tweet|
      next unless tweet.text.match? /日目/
      next if tweet.text.match? /(RT|から)/

      t = SaveTheWani::Tweet.new(
        id: tweet.id,
        text: tweet.text,
        media_url: tweet.media_url
      )
      @collection.push t
    end
  end

  class Tweet
    attr_accessor: :id, :text, :media_url
  end
end

target_user = "yuukikikuchi"

collection = []
client.user_timeline(target_user, count:300).take(1).each do |tweet|
  next unless tweet.text.match? /日目/
  next if tweet.text.match? /(RT|から)/
  binding.pry
  wani_tweet = SaveTheWani::Tweet.new id: tweet.id, text: tweet.text, media_url: tweet.media_url
  collection.push wani_tweet
end

collection
