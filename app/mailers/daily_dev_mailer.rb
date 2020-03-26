class DailyDevMailer < ApplicationMailer
  default from: -> { "DEV Digest <#{SiteConfig.default_site_email}>" }

  def daily_email(user, article)
    @user = user
    @article = article
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_daily_dev)
    subject = generate_title
    mail(to: @user.email, subject: subject)
  end

  private

  def generate_title
    "Daily Dev Article: #{@article.title} #{random_emoji}"
  end

  def random_emoji
    ["🤓", "🎉", "🙈", "🔥", "💬", "👋", "👏", "🐶", "🦁", "🐙", "🦄", "❤️", "😇"].shuffle.take(3).join
  end
end
