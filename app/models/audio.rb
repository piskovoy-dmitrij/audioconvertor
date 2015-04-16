class Audio < ActiveRecord::Base
  Paperclip::Attachment

  STATUS_NEW = 'uploaded'
  STATUS_PROCESS = 'processing'
  STATUS_CONVERTED = 'converted'
  AUDIO_PATH = '/public/uploads/audio/'
  RELATIVE_PATH = '/uploads/audio/'

  belongs_to :user
  has_and_belongs_to_many :playlists

  has_attached_file :file,
                    :path => Rails.root.to_s + self::AUDIO_PATH + ":filename",
                    :url => "/uploads/audio/:filename"
  validates_attachment_presence :file
  validates_attachment_content_type :file, :content_type => /\Aaudio\/.*\Z/

  after_initialize :init
  before_save :change_title, unless: :title?

  def self.convert(id)
    audioFile = Audio.find(id)
    audioFile.status = self::STATUS_PROCESS
    audioFile.save

    filename = audioFile.file.original_filename.split('.')[0]
    file_path = Rails.root.to_s + self::AUDIO_PATH + audioFile.file.original_filename
    cmd = "avconv -i #{file_path} -ac 2 -ab 64k #{filename + '.mp3'}"

    if system cmd
      audioFile.file.instance_write(:filename, filename + '.mp3' )
      audioFile.status = self::STATUS_CONVERTED
      audioFile.save
      FileUtils.rm file_path
    end
  end

  def self.id3_data(audio, track_id)
    TagLib::MPEG::File.open("#{Rails.root}#{self::AUDIO_PATH}#{audio.file.original_filename}") do |mp3_file|
      tag = mp3_file.id3v2_tag
      properties = mp3_file.audio_properties
      return {
                  id: audio.id,
                  track_id: track_id,
                  filename: audio.file_file_name,
                  filepath: "#{self::RELATIVE_PATH}#{audio.file.original_filename}",
                  title: tag.title,
                  artist: tag.artist,
                  duration: properties.length
             }
    end
  end

  private

  def init
    self.status ||=Audio::STATUS_NEW
  end

  def change_title
    self.title = self.file.original_filename.split('.')[0]
  end

  def title?
    return !self.title.empty?
  end

end
