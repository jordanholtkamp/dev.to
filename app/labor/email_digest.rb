# Usecase would be
# EmailDigest.send_periodic_digest_email
# OR
# EmailDigets.send_periodic_digest_email(Users.first(4))

class EmailDigest
  def self.send_periodic_digest_email(users = [])
    new(users).send_periodic_digest_email
  end

  def initialize(users = [])
    @users = users.empty? ? get_users : users
  end

  def send_periodic_digest_email
    @users.find_each do |user|
      # var set to return of EmailLogic.analyze method
      user_email_heuristic = EmailLogic.new(user).analyze
      # go to to the next unless the user should_receive_email
      next unless user_email_heuristic.should_receive_email?

      # var EmailLogic.analyze.articles_to_send
      articles = user_email_heuristic.articles_to_send

      # DigestMailer.digest_email with user and articles arguements if email_digest_periodic is true
      begin
        DigestMailer.digest_email(user, articles).deliver if user.email_digest_periodic == true
      rescue StandardError => e
        Rails.logger.error("Email issue: #{e}")
      end
    end
  end

  private

  def get_users
    User.where(email_digest_periodic: true).where.not(email: "")
  end
end
