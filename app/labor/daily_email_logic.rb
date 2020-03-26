class DailyEmailLogic
  def initialize(user)
    @user = user
  end

  def get_article_to_send
    articles_with_user_tags.
      where.not(user: @user).
      order(hotness_score: :desc).
      first
  end

  def get_user_tag_names
    Tag.where(id: @user.follows.where(followable_type: "ActsAsTaggableOn::Tag").pluck(:followable_id)).pluck(:name)
  end

  def articles_with_user_tags
    Article.tagged_with(get_user_tag_names, any: true).
      where(published: true)
  end
end
