class DigestMailer < ApplicationMailer
  default from: -> { "DEV Digest <#{SiteConfig.default_site_email}>" }

  def digest_email(user, articles)
    # instance variables set to passed in arguements
    @user = user
    @articles = articles.first(6)
    # calls generate_unsubscribe_token in ApplicationMailer with user.id and email as params
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_digest_periodic)
    subject = generate_title
    mail(to: @user.email, subject: subject)
  end

  private

  def generate_title
    # first article, article.size - 1, email end phrase (random), random_emoji
    "#{adjusted_title(@articles.first)} + #{@articles.size - 1} #{email_end_phrase} #{random_emoji}"
  end

  def adjusted_title(article)
    title = article.title.strip
    "\"#{title}\"" unless title.start_with? '"'
  end

  def random_emoji
    # random 3 emojis
    ["🤓", "🎉", "🙈", "🔥", "💬", "👋", "👏", "🐶", "🦁", "🐙", "🦄", "❤️", "😇"].shuffle.take(3).join
  end

  def email_end_phrase
    # random end phrase
    # "more trending DEV posts" won the previous split test
    # Included more often as per explore-exploit algorithm
    [
      "more trending DEV posts",
      "more trending DEV posts",
      "more trending DEV posts",
      "more trending DEV posts",
      "more trending DEV posts",
      "more trending DEV posts",
      "more trending DEV posts",
      "more trending DEV posts",
      "more trending DEV posts",
      "other posts you might like",
      "other DEV posts you might like",
      "other trending DEV posts",
      "other top DEV posts",
      "more top DEV posts",
      "more top reads from the community",
      "more top DEV posts based on your interests",
      "more trending DEV posts picked for you",
    ].sample
  end
end
