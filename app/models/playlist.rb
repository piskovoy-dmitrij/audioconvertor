class Playlist < ActiveRecord::Base
  belongs_to :user
  has_and_belongs_to_many :audios, :validate => false, dependent: :destroy

  accepts_nested_attributes_for :audios

  def self.audio_data(playlist)
    files = []
    track_id = 1

    audioFiles = playlist.audios
    audioFiles.each do |audio|
      files.push(Audio::id3_data(audio, track_id))
      track_id = track_id + 1
    end

    return files
  end
end
