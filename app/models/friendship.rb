class Friendship < ActiveRecord::Base
  belongs_to :friend, :class_name => 'User', :foreign_key => 'friend_id'
  belongs_to :user

  after_update :set_inverse_relation
  after_destroy :delete_inverse_relation

  paginates_per 15

  def set_inverse_relation
    if self.is_confirmed_changed? && self.is_confirmed
      users_reindex if Friendship.new({ friend_id: self.user_id, user_id: self.friend_id, is_confirmed: true}).save
    end
  end

  def delete_inverse_relation
    users_reindex if Friendship.delete_all(['(friend_id = ? AND user_id = ?) OR (user_id = ? AND friend_id = ?)', self.user_id, self.friend_id, self.user_id, self.friend_id])
  end

  def users_reindex
    Indexer.perform_async(:update, 'User', self.user_id) && Indexer.perform_async(:update, 'User', self.friend_id)
  end
end
