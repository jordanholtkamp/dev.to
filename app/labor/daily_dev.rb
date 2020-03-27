class DailyDev
  def self.send_daily_email
    get_users.each do |user|
      article = DailyEmailLogic.new(user).get_article_to_send
      DailyDevMailer.daily_email(user, article).deliver
    end
  end

  def self.get_users
    User.where(email_daily_dev: true).where.not(email: "")
  end
end
