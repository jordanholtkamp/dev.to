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
      # analyze email logic (look at that file for annotation on that)
      user_email_heuristic = EmailLogic.new(user).analyze
      # go to next user unless the user should receive email
      next unless user_email_heuristic.should_receive_email?

      # set articles to the return of the email logic analyze function
      articles = user_email_heuristic.articles_to_send
      begin
        # call digest email method which takes in a user and collection of articles and tell it to deliver if user is set to receive periodic digest emails
        DigestMailer.digest_email(user, articles).deliver if user.email_digest_periodic == true
      rescue StandardError => e
        # return an email error if that doesnt work for some reason?
        Rails.logger.error("Email issue: #{e}")
      end
    end
  end

  private

  def get_users
    User.where(email_digest_periodic: true).where.not(email: "")
  end
end
