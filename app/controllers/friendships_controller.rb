class FriendshipsController < ActionController::Base
  layout 'application'

  before_filter :authenticate_user!

  def index

  end

  def requests

  end

  def invites

  end

  def invite
    flash[:notice] = 'Sorry! Could not add friend!'
    friend = User.friendly.find(params[:username])
    unless friend.nil?
      flash[:notice] = 'Successfully added friend!' if current_user.invite(friend)
    end
    redirect_to friends_path
  end

  def confirm
    flash[:notice] = 'Sorry! Could not confirm friend!'
    inviter = User.friendly.find(params[:username])
    unless inviter.nil?
      flash[:notice] = 'Successfully confirmed friend!' if current_user.confirm_friendship(inviter)
    end
    redirect_to invites_friends_path
  end

  def remove
    flash[:notice] = 'Sorry, couldn\'t remove friend!'
    friend = User.friendly.find(params[:username])
    unless friend.nil?
      flash[:notice] = 'Successfully removed friend!' if current_user.remove_friendship(friend)
    end
    redirect_to friends_path
  end

  def cancel
    flash[:notice] = 'Sorry, couldn\'t cancel!'
    friend = User.friendly.find(params[:username])
    unless friend.nil?
      flash[:notice] = 'Successfully canceled!' if current_user.cancel_friendship(friend)
    end
    redirect_to friends_path
  end

  def search
    @friends = User.search(params[:q], {friendship: current_user.id}).page(params[:page]).records
  end
end