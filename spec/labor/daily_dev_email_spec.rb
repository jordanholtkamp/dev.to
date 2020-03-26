require "rails_helper"

class FakeDelegator < ActionMailer::MessageDelivery
  # TODO: we should replace all usage of .deliver to .deliver_now
  def deliver(*args)
    super
  end
end

RSpec.describe DailyDev, type: :labor do
  let(:user) { create(:user, email_daily_dev: true) }
  let(:user2) { create(:user, email_daily_dev: false) }
  let(:author) { create(:user) }
  let(:mock_delegator) { instance_double("FakeDelegator") }
  let(:ruby_tag) { create(:tag, name: "ruby") }
  let(:javaScript_tag) { create(:tag, name: "javaScript") }

  before do
    allow(DailyDevMailer).to receive(:daily_email) { mock_delegator }
    allow(mock_delegator).to receive(:deliver).and_return(true)
    user
  end

  describe "::send_daily_email" do
    context "when the user is following tags" do
      before { user.follow(ruby_tag) }

      it "send daily email" do
        article1 = create(:article, user_id: author.id, positive_reactions_count: 20, score: 20, tags: ruby_tag)
        article2 = create(:article, user_id: author.id, positive_reactions_count: 21, score: 21, tags: javaScript_tag)

        described_class.send_daily_email

        expect(DailyDevMailer).to have_received(:daily_email).with(
          user, article1
        )

        expect(DailyDevMailer).not_to have_received(:daily_email).with(
          user, article2
        )
      end
    end
  end
end
