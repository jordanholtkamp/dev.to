require "rails_helper"

class FakeDelegator < ActionMailer::MessageDelivery
  # TODO: we should replace all usage of .deliver to .deliver_now
  def deliver_now(*args)
    super
  end
end

RSpec.describe DailyDev, type: :labor do
  let(:user) { create(:user, email_daily_dev: true, email: "jordanholtkamp@gmail.com") }
  let(:user2) { create(:user, email_daily_dev: false) }
  let(:author) { create(:user) }
  let(:mock_delegator) { instance_double("FakeDelegator") }
  let(:ruby_tag) { create(:tag, name: "ruby") }
  let(:python_tag) { create(:tag, name: "python") }
  let(:javaScript_tag) { create(:tag, name: "javaScript") }

  before do
    allow(DailyDevMailer).to receive(:daily_email) { mock_delegator }
    allow(mock_delegator).to receive(:deliver_now).and_return(true)
    user
  end

  describe "::send_daily_email" do
    context "when the user is following tags" do
      before { [user.follow(ruby_tag), user.follow(python_tag)] }

      it "sends article that has a tag the user is following" do
        article1 = create(:article, user_id: author.id, positive_reactions_count: 20, hotness_score: 10, tags: ruby_tag)
        article2 = create(:article, user_id: author.id, positive_reactions_count: 21, hotness_score: 21, tags: javaScript_tag)
        article3 = create(:article, user_id: author.id, positive_reactions_count: 21, hotness_score: 30, tags: python_tag)

        article1.tags << python_tag

        described_class.send_daily_email

        expect(DailyDevMailer).to have_received(:daily_email).with(
          user, article3
        )

        expect(DailyDevMailer).not_to have_received(:daily_email).with(
          user, article2
        )

        expect(DailyDevMailer).not_to have_received(:daily_email).with(
          user, article1
        )
      end
    end

    context "when the user is not following tags" do
      it "sends a the hottest article" do
        article1 = create(:article, user_id: author.id, positive_reactions_count: 20, hotness_score: 10, tags: ruby_tag)
        article2 = create(:article, user_id: author.id, positive_reactions_count: 21, hotness_score: 21, tags: javaScript_tag)

        described_class.send_daily_email

        expect(DailyDevMailer).to have_received(:daily_email).with(
          user, article2
        )

        expect(DailyDevMailer).not_to have_received(:daily_email).with(
          user, article1
        )
      end
    end
  end
end
