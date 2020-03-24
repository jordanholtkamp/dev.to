class AddEmailDailyDevToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :email_daily_dev, :boolean, default: false
  end
end
