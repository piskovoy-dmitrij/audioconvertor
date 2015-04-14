class PlaylistsController < ApplicationController

  # GET /playlists
  # GET /playlists.json
  def index
    respond_to do |format|
      format.html
      format.json { render json: [{name: 'Playlist1', files: []}] }
    end
  end

  def create

  end

  def new

  end

  private

  def playlist_params
    params.require(:playlist).permit(:name)
  end
end
