class AudiosController < ApplicationController
  protect_from_forgery with: :exception

  def index

  end

  def new
    redirect_to new_user_session_path unless user_signed_in?
    @audio = Audio.new
  end

  def create
    @audio = Audio.new(audio_params)
    @audio.user = current_user

    if @audio.save
      AudioConvert.perform_async(@audio.id)
      redirect_to audios_path, notice: 'Audio was successfully created.'
    else
      render new_audio_path
    end
  end

  private

  def audio_params
    params.require(:audio).permit(:title, :file)
  end
end
