class EmailLogic
  # gives us access to these methods anywhere where we can call the class
  attr_reader :open_percentage, :last_email_sent_at, :days_until_next_email, :articles_to_send

  def initialize(user)
    # initializing with a user and a bunch of nil attributes
    @user = user
    @open_percentage = nil
    @ready_to_receive_email = nil
    @last_email_sent_at = nil
    @days_until_next_email = nil
    @articles_to_send = []
  end

  def analyze
    # setting this instance var to equal when the last digest email was sent
    @last_email_sent_at = get_last_digest_email_user_received
    # setting instance var equal to our private helper (doing this for the rest of these. look at helpers for more info on what they do)
    @open_percentage = get_open_rate
    @days_until_next_email = get_days_until_next_email
    @ready_to_receive_email = get_user_readiness
    @articles_to_send = get_articles_to_send if @ready_to_receive_email
    self
  end

  def should_receive_email?
    @ready_to_receive_email
  end

  private

  def get_articles_to_send
    # get fresh date from helper (look there)
    fresh_date = get_fresh_date

    # set articles var equal to this long if else statement return
    articles = if user_has_followings?

                 experience_level_rating = (@user.experience_level || 5)
                 experience_level_rating_min = experience_level_rating - 3.6
                 experience_level_rating_max = experience_level_rating + 3.6

                 # look for the followeed articles a user has
                 @user.followed_articles.
                   # where published at date is more recent than the fresh date
                   where("published_at > ?", fresh_date).
                   # where the article is published and eligible to be sent as a digest
                   where(published: true, email_digest_eligible: true).
                   #  where it is not the user's own article
                   where.not(user_id: @user.id).
                   #  article score is greater than 12
                   where("score > ?", 12).
                   # where the experience is between the max and min
                   where("experience_level_rating > ? AND experience_level_rating < ?",
                         experience_level_rating_min, experience_level_rating_max).
                   #  order so highest scores will be on top
                   order("score DESC").
                   # limit 8 articles
                   limit(8)
               else
                 # if the user does not have followings, look for an article...
                 Article.published.
                   # where published date is more recent than fresh date
                   where("published_at > ?", fresh_date).
                   #  where it is featured and eligible for digest
                   where(featured: true, email_digest_eligible: true).
                   # and was not written by the user
                   where.not(user_id: @user.id).
                   #  where article score is better than 25
                   where("score > ?", 25).
                   #  order so highest scores will be on top
                   order("score DESC").
                   # limit 8
                   limit(8)
               end

    # user is not readyto receive email if the return of articles if/else is less than 3
    @ready_to_receive_email = false if articles.length < 3

    # return articles
    articles
  end

  def get_days_until_next_email
    # Relies on hyperbolic tangent function to model the frequency of the digest email
    max_day = SiteConfig.periodic_email_digest_max
    min_day = SiteConfig.periodic_email_digest_min
    result = max_day * (1 - Math.tanh(2 * @open_percentage))
    result = result.round
    # if the max day email result is less than the min day, return the result, otherwise, the min day amount
    result < min_day ? min_day : result
  end

  def get_open_rate
    # get the last 10 digest emails the user received
    past_sent_emails = @user.email_messages.where(mailer: "DigestMailer#digest_email").limit(10)

    # count the amount of digest emails they got (limit 10)
    past_sent_emails_count = past_sent_emails.count

    # Will stick with 50% open rate if @user has no/not-enough email digest history
    return 0.5 if past_sent_emails_count < 10

    # shows us how many emails the user has opened out of their last 10 using a nice sql fragment i might add ;)
    past_opened_emails_count = past_sent_emails.where("opened_at IS NOT NULL").count
    # get the percentage by divinding opened by total
    past_opened_emails_count / past_sent_emails_count
  end

  def get_user_readiness
    # hard return true if they have not gotten a digest email
    return true unless @last_email_sent_at

    # Has it been at least x days since @user received an email?
    Time.current - @last_email_sent_at >= @days_until_next_email.days.to_i
  end

  def get_last_digest_email_user_received
    # find digest emails that the user gets, get the most recent one and return the sent at time
    @user.email_messages.where(mailer: "DigestMailer#digest_email").last&.sent_at
  end

  def get_fresh_date
    # set this to var to 4 days ago
    a_few_days_ago = 4.days.ago.utc
    # return 4 days ago unless they have gotten a digest email
    return a_few_days_ago unless @last_email_sent_at

    # if 4 days is greater than when the last digest email was sent, return 4 days, otherwise return when the last email was sent
    a_few_days_ago > @last_email_sent_at ? a_few_days_ago : @last_email_sent_at
  end

  def user_has_followings?
    # looks if the user is following any other users
    following_users = @user.cached_following_users_ids
    # looks for tags the user is following
    following_tags = @user.cached_followed_tag_names
    # returns true if they are following any tags or other users
    following_users.any? || following_tags.any?
  end
end
