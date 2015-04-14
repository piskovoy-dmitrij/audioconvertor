class UsersController < ApplicationController
  def list
    @users = User.search(params[:q]).page(params[:page]).records
  end

  def search
    @users = User.search(params[:q]).page(params[:page]).records

    render action: 'index'
  end
end
