class DailyEmailLogic
  def initialize(user)
    @user = user
  end

  def get_article_to_send
    Article.
      where.not(user: @user).
      first
  end
end
