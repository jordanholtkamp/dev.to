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

  # sends the users a digest email
  def send_periodic_digest_email
    # finds users linked to the email digest and for each user sends them the email.
    @users.find_each do |user|
      user_email_heuristic = EmailLogic.new(user).analyze
      # check if each user is supposed to receive an email if so send it. If not go to next user.
      next unless user_email_heuristic.should_receive_email?

      articles = user_email_heuristic.articles_to_send
      # sends an email
      begin
        DigestMailer.digest_email(user, articles).deliver if user.email_digest_periodic == true
      # if email fails log an error
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
