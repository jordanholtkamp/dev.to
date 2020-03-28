class DailyEmailLogic
  def initialize(user)
    @user = user
  end

  def get_article_to_send
    if get_user_tag_names != []
      Article.tagged_with(get_user_tag_names, any: true).
        where(published: true).
        where.not(user: @user).
        order(hotness_score: :desc).
        first
    else
      Article.where(published: true).
        where.not(user: @user).
        order(hotness_score: :desc).
        first
    end
  end

  def get_user_tag_names
    Tag.where(id: @user.follows.where(followable_type: "ActsAsTaggableOn::Tag").pluck(:followable_id)).pluck(:name)
  end
end
