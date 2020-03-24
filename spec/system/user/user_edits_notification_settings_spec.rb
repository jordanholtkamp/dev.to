require "rails_helper"

RSpec.describe "User edits their email preferences", type: :system do
  let(:user) { create(:user, saw_onboarding: true) }
  let(:github_response_body) do
    [
      {
        "id" => 1_296_269,
        "node_id" => "MDEwOlJlcG9zaXRvcnkxMjk2MjY5",
        "name" => "Hello-World",
        "full_name" => "octocat/Hello-World"
      },
    ]
  end

  before do
    sign_in user
    stub_request(:get, "https://api.github.com/user/repos?per_page=100").to_return(status: 200, body: github_response_body.to_json, headers: { "Content-Type" => "application/json" })
  end

  describe "When I go to my notification settings" do
    before do
      visit "/settings/notifications"
    end

    it "has checkboxes" do
      expect(page).to have_unchecked_field(:user_email_daily_dev)
      expect(page).to have_checked_field(:user_email_badge_notifications)
      expect(page).to have_checked_field(:user_email_comment_notifications)
      expect(page).to have_checked_field(:user_email_connect_messages)
      expect(page).to have_checked_field(:user_email_follower_notifications)
      expect(page).to have_checked_field(:user_email_mention_notifications)
      expect(page).to have_checked_field(:user_email_newsletter)
    end

    it "allows me to change email preferences" do
      check :user_email_daily_dev

      click_on "SUBMIT"

      user.reload

      expect(page).to have_current_path("/settings/notifications")
      expect(page).to have_checked_field(:user_email_daily_dev)
      expect(page).to have_content("Your profile was successfully updated.")
      expect(user.email_daily_dev).to be_truthy
    end
  end
end
