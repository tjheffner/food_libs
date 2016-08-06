require 'twitter_ebooks'

# Information about a particular Twitter user we know
class UserInfo
  attr_reader :username

  # @return [Integer] how many times we can pester this user unprompted
  attr_accessor :pesters_left

  # @param username [String]
  def initialize(username)
    @username = username
    @pesters_left = 1
  end
end

# This is an example bot definition with event handlers commented out
# You can define and instantiate as many bots as you like
class MyBot < Ebooks::Bot
  # Configuration here applies to all MyBots
  attr_accessor :original, :model, :model_path

  def configure
    # Consumer details come from registering an app at https://dev.twitter.com/
    # Once you have consumer details, use "ebooks auth" for new access tokens
    self.consumer_key = 'zcV9SzjxEWu0oQnua7nH1yrBW' # Your app consumer key
    self.consumer_secret = 'J8OdJ6zZ1Pe7G1kV1MUN3oidZuhGW7BwAQNWrLfjk4AP5uEawp' # Your app consumer secret

    # Users to block instead of interacting with
    self.blacklist = ['food_libs']

    # Range in seconds to randomize delay when bot.delay is called
    self.delay_range = 1..6
  end

  def top100; @top100 ||= model.keywords.take(100); end
  def top20;  @top20  ||= model.keywords.take(20); end

  def on_startup
    load_model!

    scheduler.cron '0 0 * * *' do
         # Each day at midnight, post a single tweet
         tweet(model.make_statement)
    end

    scheduler.every '2h' do
        statement = model.make_statement
        tweet(statement)
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
    # Become more inclined to pester a user when they talk to us
    userinfo(tweet.user.screen_name).pesters_left += 1

    delay do
      reply(tweet, model.make_response(meta(tweet).mentionless, meta(tweet).limit))
    end
  end

  def on_timeline(tweet)
    return if tweet.retweeted_status?
      return unless can_pester?(tweet.user.screen_name)

      tokens = Ebooks::NLP.tokenize(tweet.text)

      interesting = tokens.find { |t| top100.include?(t.downcase) }
      very_interesting = tokens.find_all { |t| top20.include?(t.downcase) }.length > 2

      delay do
        if very_interesting
          favorite(tweet) if rand < 0.5
          retweet(tweet) if rand < 0.1
          if rand < 0.01
            userinfo(tweet.user.screen_name).pesters_left -= 1
            reply(tweet, model.make_response(meta(tweet).mentionless, meta(tweet).limit))
          end
        elsif interesting
          favorite(tweet) if rand < 0.05
          if rand < 0.001
            userinfo(tweet.user.screen_name).pesters_left -= 1
            reply(tweet, model.make_response(meta(tweet).mentionless, meta(tweet).limit))
          end
        end
      end
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
  bot.access_token = "761806052316753924-tpnqEkdB3RUGAHEH0BlIM3CuYSi7IxE" # Token connecting the app to this account
  bot.access_token_secret = "yBlzOAqPkTNLQUf9LzGCXipe9YKJI4xsELmhm12vFci6D" # Secret connecting the app to this account

  bot.original = "foodpyramids"
end
