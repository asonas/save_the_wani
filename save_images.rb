require 'twitter'
require 'pp'
require 'pry'
require 'fileutils'
require 'google/cloud/vision'

class SaveTheWani
  #初日だけフォーマットが違うので例外として扱う
  TWEET_ID_OF_FIRST_DAY = 1205120078322159617
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
    #download_image
    check
    annotation

    dump_json
  end

  def annotation
    annotator = Google::Cloud::Vision::ImageAnnotator.new
    @collection.each do |tweet|
      res = annotator.text_detection(image: tweet.file_path).responses
      res.each do |res|
        res.text_annotations.each do |text|
          tweet.media_descriptions.push text.description
        end
      end
    end
  end

  def search
    tweets = @client.user_timeline(AUTHOR, count:200)
    cleansed(tweets)
    last_tweet = tweets.last
    tweets = @client.user_timeline(AUTHOR, count:200, max_id: last_tweet.id)
    cleansed(tweets)
  end

  def cleansed(tweets)
    tweets.each do |tweet|
      next unless tweet.text.match? /(日目|日後)/
      next if tweet.text.match? /(RT|から|個展|アカウント|100均に行く|インスタ|LINE)/

      t = SaveTheWani::Tweet.new(
        id: tweet.id,
        text: tweet.text,
        media_url: tweet.media.first.media_url
      )
      @collection.push t
    end
  end

  def check
    p (1..100).to_a - JSON.parse(File.open("tweets.json").read).map { |j| j["day"].to_i }.sort
  end

  def dump_json
    hash = @collection.map(&:to_hash)
    json = JSON.fast_generate(hash)

    File.open('tweets.json', 'wb') do |fp|
      fp.write json
    end
  end

  def download_image
    FileUtils.mkdir_p 'assets'
    @collection.each do |t|
      system 'wget',
        t.media_url,
        "-O",
        t.file_path
    end
  end

  class Tweet
    attr_accessor :id, :text, :media_url, :media_descriptions

    def initialize(id:, text:, media_url:)
      @id = id
      @text = text
      @media_url = media_url
      @media_descriptions = []
    end

    def to_hash
      h = {
        id: @id,
        text: @text,
        day: day,
        file_path: file_path,
        media: {
          url: @media_url,
          descriotions: @media_descriptions
        }
      }
    end

    def file_name
      uri = URI.parse @media_url
      uri.path.sub('/media/', '')
    end

    def file_path
      "assets/#{file_name}"
    end

    def day
      if @id == TWEET_ID_OF_FIRST_DAY
        1
      else
        d = text.match(/\d+日目/).to_s.scan /\d+/
        d.first.to_i
      end
    end
  end
end

SaveTheWani.run
