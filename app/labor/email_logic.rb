class EmailLogic
  # attr_reader giving access to calling the methods in initialize anywhere we have access to the class
  attr_reader :open_percentage, :last_email_sent_at, :days_until_next_email, :articles_to_send

  # initializing class with user object open_percentage - articles_to_send and setting all values as nil
  # articles_to_send is equal to an empty array
  def initialize(user)
    @user = user
    @open_percentage = nil
    @ready_to_receive_email = nil
    @last_email_sent_at = nil
    @days_until_next_email = nil
    @articles_to_send = []
  end

  def analyze
    # setting instance variables equal to the return value of these methods
    @last_email_sent_at = get_last_digest_email_user_received
    @open_percentage = get_open_rate
    @days_until_next_email = get_days_until_next_email
    @ready_to_receive_email = get_user_readiness
    @articles_to_send = get_articles_to_send if @ready_to_receive_email
    self
  end

  def should_receive_email?
    # returns true or false from ready_to_receive_email
    @ready_to_receive_email
  end

  # methods are private and only avaliable to the class
  private

  def get_articles_to_send
    # set var to return of get_fresh_date
    fresh_date = get_fresh_date

    # if user_has_followings is exists, run lines 39-61, otherwise 62-78
    articles = if user_has_followings?
                 # if user.experience_level exists use that otherwise use 5
                 experience_level_rating = (@user.experience_level || 5)
                 # subtract 3.6 from experience_level_rating
                 experience_level_rating_min = experience_level_rating - 3.6
                 # add 3.6 to experience_level_rating
                 experience_level_rating_max = experience_level_rating + 3.6

                 # AR query where followed_articles were published after fresh date
                 @user.followed_articles.
                   where("published_at > ?", fresh_date).
                   # article was published and eligible to be sent through email digest
                   where(published: true, email_digest_eligible: true).
                   # not the user's own article
                   where.not(user_id: @user.id).
                   # article score is greater than 12
                   where("score > ?", 12).
                   # user where experience_level_rating is between the rating min and max
                   where("experience_level_rating > ? AND experience_level_rating < ?",
                         experience_level_rating_min, experience_level_rating_max).
                   # ord desc and limit to 8
                   order("score DESC").
                   limit(8)
               # otherwise
               else
                 # AR querty to find the Article published
                 Article.published.
                   # after fresh_date
                   where("published_at > ?", fresh_date).
                   # featured is true, is email_digest_eligible
                   where(featured: true, email_digest_eligible: true).
                   # not equal to user.id
                   where.not(user_id: @user.id).
                   # score has to be greater than 25
                   where("score > ?", 25).
                   # order desc and limit to 8
                   order("score DESC").
                   limit(8)
               end
    # ready_to_receive_email is false if articles.length is less than 3
    @ready_to_receive_email = false if articles.length < 3

    articles
  end

  def get_days_until_next_email
    # Relies on hyperbolic tangent function to model the frequency of the digest email
    max_day = SiteConfig.periodic_email_digest_max
    min_day = SiteConfig.periodic_email_digest_min
    result = max_day * (1 - Math.tanh(2 * @open_percentage))
    result = result.round
    # if result is less than min_day is true, return min_day else return result
    result < min_day ? min_day : result
  end

  def get_open_rate
    # get the last 10 digets emails the user has received
    past_sent_emails = @user.email_messages.where(mailer: "DigestMailer#digest_email").limit(10)

    # count the amount of past sent emails
    past_sent_emails_count = past_sent_emails.count

    # Will stick with 50% open rate if @user has no/not-enough email digest history
    # return .5 if past past_sent_emails_count is less than 10, once 11 emails have been sentlines 88 and 89 will run
    return 0.5 if past_sent_emails_count < 10

    # if the emails have been opened, count them
    past_opened_emails_count = past_sent_emails.where("opened_at IS NOT NULL").count
    # divide opened emails by # of emails sent
    past_opened_emails_count / past_sent_emails_count
  end

  def get_user_readiness
    # method evaluates if user is ready for another digest email
    # return true if they have not received email
    return true unless @last_email_sent_at

    # Has it been at least x days since @user received an email?
    Time.current - @last_email_sent_at >= @days_until_next_email.days.to_i
  end

  def get_last_digest_email_user_received
    # user email_messages where the mailer name is = "DigestMailer#digest_email",
    # if .last does not exist, return nil
    @user.email_messages.where(mailer: "DigestMailer#digest_email").last&.sent_at
  end

  def get_fresh_date
    # variable set to time 4 days ago UTC time
    a_few_days_ago = 4.days.ago.utc
    # return a few_days_ago if @last_email_sent_at/get_last_digest_email_user_received
    # does not exist is equal to nil
    return a_few_days_ago unless @last_email_sent_at

    # if a few_days_ago is less than @last_email_sent_at return a few_days_ago
    # else return @last_email_sent_at
    a_few_days_ago > @last_email_sent_at ? a_few_days_ago : @last_email_sent_at
  end

  def user_has_followings?
    # var = user.cached_following_users_ids attribute, can be nil
    following_users = @user.cached_following_users_ids
    # var = user.cached_following_users_ids attribute, can be nil
    following_tags = @user.cached_followed_tag_names
    # checks if either user is following any users or tags, returns true or false
    following_users.any? || following_tags.any?
  end
end
