class RemoveVkontakteUid < ActiveRecord::Migration
  def change
    remove_index :users, :vkontakte_uid

    remove_column :users, :vkontakte_uid
  end
end
