class AddUserFields < ActiveRecord::Migration
  def change
    add_column :users, :facebook_uid, :string
    add_column :users, :twitter_uid, :string
    add_column :users, :gplus_uid, :string
    add_column :users, :vkontakte_uid, :string
    add_column :users, :name, :string
    add_column :users, :birth_date, :date

    add_index :users, :facebook_uid
    add_index :users, :twitter_uid
    add_index :users, :gplus_uid
    add_index :users, :vkontakte_uid

    remove_index :users, :email

    add_index :users, :email
  end
end
