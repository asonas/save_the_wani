require 'twitter'
require 'pp'
require 'pry'
require 'fileutils'

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
    new.run
  end

  def run
    search
    dump
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
      @collection.push t
    end
  end

  def dump
    download
    dump_json
  end

  def dump_json
    hash = @collection(&:to_hash)
    JSON.fast_generate(hash)
  end

  def download
    FileUtils.mkdir_p 'assets'
    @collection.each do |t|
      system 'wget',
        t.media_url,
        "-Passets"
    end
  end

  def dump

  class Tweet
    attr_accessor :id, :text, :media_url

    def initialize(id:, text:, media_url:)
      @id = id
      @text = text
      @media_url = media_url
    end

    def to_hash
      h = {
        id: @id,
        text: @text,
        media_url: @media_url,
        save_path: save_path
      }
    end

    def file_name
      uri = URI.parse @media_url
      uri.path.sub('/', '')
    end

    def save_path
      "assets/#{file_name}"
    end
  end
end

SaveTheWani.run
