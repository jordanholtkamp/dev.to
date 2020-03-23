require "rails_helper"

def user_grants_authorization_on_github_popup(github_callback_hash)
  OmniAuth.config.add_mock(:github, github_callback_hash)
end

def user_does_not_grant_authorization_on_github_popup
  OmniAuth.config.mock_auth[:github] = :invalid_credentials
end

RSpec.describe "Authenticating with GitHub" do
  let(:github_callback_hash) do
    {
      provider: "GitHub",
      uid: "111111",
      credentials: {
        token: "222222",
        secret: "333333"
      },
      extra: {
        access_token: "",
        raw_info: {
          name: "Bruce Wayne",
          created_at: "Thu Jul 4 00:00:00 +0000 2013" # This is mandatory
        }
      },
      info: {
        nickname: "batman",
        name: "Bruce Wayne",
        email: "batman@batcave.com"
      }
    }
  end

  context "when user is new to dev.to" do
    it "user can login with github credentials" do
      user_grants_authorization_on_github_popup(github_callback_hash)
      visit root_path

      click_link "Sign In With GitHub"
      expect(page.html).to include("onboarding-container")
    end

    it "user cannot login in to github using invalid credentials" do
      user_does_not_grant_authorization_on_github_popup

      visit root_path
      click_link "Sign In With Twitter"

      expect(page).to have_link "Sign In/Up"
      expect(page).to have_link "Via Twitter"
      expect(page).to have_link "Via GitHub"
      expect(page).to have_link "All about dev.to"
    end
  end
end
