class DigestMailer < ApplicationMailer
  default from: -> { "DEV Digest <#{SiteConfig.default_site_email}>" }
# finds user, articles and unsubscribe token
  def digest_email(user, articles)
    # sets user
    @user = user
    # sets first 6 articles
    @articles = articles.first(6)
    # sets unsubscribe token
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_digest_periodic)
    subject = generate_title
    mail(to: @user.email, subject: subject)
  end

  private
# creates a title from the articles
  def generate_title
    "#{adjusted_title(@articles.first)} + #{@articles.size - 1} #{email_end_phrase} #{random_emoji}"
  end
# modifies the title 
  def adjusted_title(article)
    title = article.title.strip
    "\"#{title}\"" unless title.start_with? '"'
  end
# grabs a random emoji from the array
  def random_emoji
    ["🤓", "🎉", "🙈", "🔥", "💬", "👋", "👏", "🐶", "🦁", "🐙", "🦄", "❤️", "😇"].shuffle.take(3).join
  end
# ends the email with a phrase
  def email_end_phrase
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
