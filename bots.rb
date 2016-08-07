require 'twitter_ebooks'
require 'dotenv'
Dotenv.load(".env")

CONSUMER_KEY = ENV['EBOOKS_CONSUMER_KEY']
CONSUMER_SECRET = ENV['EBOOKS_CONSUMER_SECRET']
OAUTH_TOKEN = ENV['EBOOKS_OAUTH_TOKEN']
OAUTH_TOKEN_SECRET = ENV['EBOOKS_OAUTH_TOKEN_SECRET']

# This is an example bot definition with event handlers commented out
# You can define and instantiate as many bots as you like
class MyBot < Ebooks::Bot
  # Configuration here applies to all MyBots
  attr_accessor :original, :model, :model_path

  def configure
    # Consumer details come from registering an app at https://dev.twitter.com/
    # Once you have consumer details, use "ebooks auth" for new access tokens
    self.consumer_key = CONSUMER_KEY # Your app consumer key
    self.consumer_secret = CONSUMER_SECRET # Your app consumer secret

    # Users to block instead of interacting with
    self.blacklist = ['food_libs']

    # Range in seconds to randomize delay when bot.delay is called
    self.delay_range = 1..6
  end

  def top100; @top100 ||= model.keywords.take(100); end
  def top20;  @top20  ||= model.keywords.take(20); end

  def on_startup
    load_model!

    # verify random works
    tweet(Random.rand(10...42))

    # scheduler.cron '0 0 * * *' do
    #      # Each day at midnight, post a single tweet
    #      tweet(model.make_statement)
    # end

    scheduler.every '5m' do

        # generate parts of a tweet
        smaller = model.make_statement(30)
        statement = model.make_statement(Random.rand(25...60))
        suffix = model.make_statement(Random.rand(2...30))

        # randomize order that tweet is composed
        letters = [smaller, statement, suffix]
        letters = letters.shuffle

        # make sure it's spaced okay
        tweet(letters[0] + ' ' +letters[1] + ' ' + letters[2])
    end

  end

  def on_message(dm)
    delay do
        reply(dm, model.make_response(dm.text))
    end
  end

  def on_follow(user)
    # Follow a user back
    follow(user.screen_name)
  end

  def on_mention(tweet)
    # Reply to a mention
  end

  def on_timeline(tweet)

  end

  private
  def load_model!
    return if @model

    @model_path ||= "model/#{original}.model"

    log "Loading model #{model_path}"
    @model = Ebooks::Model.load(model_path)
  end
end

# Make a MyBot and attach it to an account
MyBot.new("food_libs") do |bot|
  bot.access_token = OAUTH_TOKEN # Token connecting the app to this account
  bot.access_token_secret = OAUTH_TOKEN_SECRET # Secret connecting the app to this account

  bot.original = "foodpyramids"
end
