class AudioConvert
  include Sidekiq::Worker

  def perform(id)
    Audio.convert(id)
  end
end