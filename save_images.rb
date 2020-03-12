require 'twitter'
require 'pp'
require 'pry'

class SaveTheWani
  AUTHOR = "yuukikikuchi"

  def initialize
    @collection = []
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key    = ENV['TWITTER_API_KEY']
      config.consumer_secret = ENV['TWITTER_API_SECRET']
      config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
      config.access_token_secret = ENV['TWITTER_ACCESS_SECRET']
    end
  end

  def self.run
    new.search
    p @collection.map(&:media_url)
  end

  def search
    @client.user_timeline(AUTHOR, count:300).take(1).each do |tweet|
      next unless tweet.text.match? /日目/
      next if tweet.text.match? /(RT|から)/

      t = SaveTheWani::Tweet.new(
        id: tweet.id,
        text: tweet.text,
        media_url: tweet.media.first.media_url
      )
      binding.pry
      @collection.push t
    end
  end

  class Tweet
    attr_accessor :id, :text, :media_url

    def initialize(id:, text:, media_url:)
      @id = id
      @text = text
      @media_url = media_url
    end
  end
end

SaveTheWani.run


