class PlaylistsController < ApplicationController
  require 'taglib'

  protect_from_forgery with: :null_session

  def index
    result = []

    list = Playlist.all()
    list.each do |playlist|
      files = Playlist::audio_data(playlist)
      result.push({id: playlist.id, name: playlist.name, files: files})
    end

    render json: result
  end

  def new

  end

  def create

    puts "params: "
    puts params

    @playlist = Playlist.new(playlist_params)

    if @playlist.save
      files = params[:files]
      files.each do |data|
        @playlist.audios<<(Audio.find(data[:id]))
      end
    end

    render json: {name: @playlist.name}
  end

  def show
    playlist = Playlist.find(params[:id])
    render json: {id: playlist.id, name: playlist.name, files: Playlist::audio_data(playlist)}
  end

  def edit

  end

  def update
    playlist = Playlist.find(params[:id])
    playlist.audios.clear
    files = params[:files]
    files.each do |data|
      @playlist.audios<<(Audio.find(data[:id]))
    end
  end

  def destroy

    playlist = Playlist.find(params[:id])
    playlist.audios.clear
    playlist.destroy()

    render json: {status: 'Success'}
  end

  private

  def playlist_params
    params.require(:playlist).permit(:name)
    end
end
