class Audio < ActiveRecord::Base
  Paperclip::Attachment

  STATUS_NEW = 'uploaded'
  STATUS_PROCESS = 'processing'
  STATUS_CONVERTED = 'converted'
  AUDIO_PATH = '/public/uploads/audio/'

  belongs_to :user

  has_attached_file :file,
                    :path => Rails.root.to_s + self::AUDIO_PATH + ":filename",
                    :url => "/uploads/audio/:filename"
  validates_attachment_presence :file
  validates_attachment_content_type :file, :content_type => /\Aaudio\/.*\Z/

  after_initialize :init

  def self.convert(id)
    audioFile = Audio.find(id)
    audioFile.status = Audio::STATUS_PROCESS
    audioFile.save

    filename = audioFile.file.original_filename.split('.')[0]
    file_path = Rails.root.to_s + self::AUDIO_PATH + audioFile.file.original_filename
    cmd = "avconv -i #{file_path} -ac 2 -ab 64k #{filename + '.ogg'}"

    if system cmd
      audioFile.file.instance_write(:filename, filename + '.ogg' )
      audioFile.status = Audio::STATUS_CONVERTED
      audioFile.save
      FileUtils.rm file_path
    end
  end

  private

  def init
    self.status ||=Audio::STATUS_NEW
  end

end
