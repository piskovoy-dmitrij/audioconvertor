class UsersController < ApplicationController
  def search
    @users = User.search(params[:q]).page(params[:page]).records

    render action: 'index'
  end
end
