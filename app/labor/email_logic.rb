class EmailLogic
  # attr_reader gives access to these methods in the class
  attr_reader :open_percentage, :last_email_sent_at, :days_until_next_email, :articles_to_send
  # initializes with the user and nil attributes
  def initialize(user)
    @user = user
    @open_percentage = nil
    @ready_to_receive_email = nil
    @last_email_sent_at = nil
    @days_until_next_email = nil
    @articles_to_send = []
  end

  def analyze
    # assigns last_email_sent_at to the value grabbed from get_last_digest_email_user_received
    @last_email_sent_at = get_last_digest_email_user_received
    # assigns open_percentage to the value grabbed from get_open_rate
    @open_percentage = get_open_rate
    # assigns days_until_next_email to the value grabbed from get_days_until_next_email
    @days_until_next_email = get_days_until_next_email
    # assigns ready_to_receive_email to the value grabbed from get_user_readiness
    @ready_to_receive_email = get_user_readiness
    # assigns articles_to_send to the value grabbed from get_articles_to_send if @ready_to_receive_email is true
    @articles_to_send = get_articles_to_send if @ready_to_receive_email
    self
  end

  # assigns ready_to_receive_email to true or false
  def should_receive_email?
    @ready_to_receive_email
  end
  # Methods below this are private and only available to the class

  private

  def get_articles_to_send
    # assign fresh_date to the value from get_fresh_date
    fresh_date = get_fresh_date
    # Set articles equal to a boolean if they follow something
    articles = if user_has_followings?
                 experience_level_rating = (@user.experience_level || 5)
                 experience_level_rating_min = experience_level_rating - 3.6
                 experience_level_rating_max = experience_level_rating + 3.6
                 @user.followed_articles.
                   # looks at where published_at is more recent than fresh_date
                   where("published_at > ?", fresh_date).
                   # looks at where published and email_digest_eligible is true
                   where(published: true, email_digest_eligible: true).
                   # looks at where user_id is not their own user.id
                   where.not(user_id: @user.id).
                   # looks at where the score is greater 12
                   where("score > ?", 12).
                   # looks at where the experience is between the max and the min
                   where("experience_level_rating > ? AND experience_level_rating < ?",
                         experience_level_rating_min, experience_level_rating_max).
                   # order by descending
                   order("score DESC").
                   limit(8)
               else
                 Article.published.
                   # looks at where published_at is more recent than fresh_date
                   where("published_at > ?", fresh_date).
                   # looks at where published and email_digest_eligible is true
                   where(featured: true, email_digest_eligible: true).
                   # looks at where user_id is not their own user.id
                   where.not(user_id: @user.id).
                   # looks at where the score is greater 25
                   where("score > ?", 25).
                   # order by descending
                   order("score DESC").
                   limit(8)
               end
    # assigns ready_to_receive_email to false if the articles length is less than 3
    @ready_to_receive_email = false if articles.length < 3
    # return the articles
    articles
  end

  def get_days_until_next_email
    # Relies on hyperbolic tangent function to model the frequency of the digest email
    max_day = SiteConfig.periodic_email_digest_max
    min_day = SiteConfig.periodic_email_digest_min
    result = max_day * (1 - Math.tanh(2 * @open_percentage))
    result = result.round
    # if the result is less than the min day, use min_day otherwise use result
    result < min_day ? min_day : result
  end

  def get_open_rate
    # Get the last 10 digest emails the user received
    past_sent_emails = @user.email_messages.where(mailer: "DigestMailer#digest_email").limit(10)
    # Count the amount of past sent emails.
    past_sent_emails_count = past_sent_emails.count

    # Will stick with 50% open rate if @user has no/not-enough email digest history
    # Return .5 if the past emails count is less than 10
    return 0.5 if past_sent_emails_count < 10

    # Dont run these lines if there is less than 10 emails
    past_opened_emails_count = past_sent_emails.where("opened_at IS NOT NULL").count
    past_opened_emails_count / past_sent_emails_count
  end

  # evaluates if the user is ready for another digest email
  def get_user_readiness
    # retrun true if they have not received an email
    return true unless @last_email_sent_at

    # Has it been at least x days since @user received an email?
    Time.current - @last_email_sent_at >= @days_until_next_email.days.to_i
  end

  # Grabs the users email_messages where mailer name is equal to string, then if .last non existent return nil
  def get_last_digest_email_user_received
    @user.email_messages.where(mailer: "DigestMailer#digest_email").last&.sent_at
  end

  def get_fresh_date
    a_few_days_ago = 4.days.ago.utc
    # return a_few_days_ago if last_email_sent_at nil
    return a_few_days_ago unless @last_email_sent_at

    # if a_few_days_ago greater than last_email_sent_at return a_few_days_ago if not last_email_sent_at
    a_few_days_ago > @last_email_sent_at ? a_few_days_ago : @last_email_sent_at
  end

  # Checks if the user has followings.
  def user_has_followings?
    # assign following_users to the user ids of any followed users by the user
    following_users = @user.cached_following_users_ids
    # assign following_tags to the tag names of any followed tags by the user
    following_tags = @user.cached_followed_tag_names
    # checks if following users or tags has a value
    following_users.any? || following_tags.any?
  end
end
