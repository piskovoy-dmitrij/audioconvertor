class Audio < ActiveRecord::Base
  Paperclip::Attachment

  STATUS_NEW = 'uploaded'
  STATUS_PROCESS = 'processing'
  STATUS_CONVERTED = 'converted'

  belongs_to :user

  has_attached_file :file,
                    :path => Rails.root.to_s + "/public/uploads/audio/:filename",
                    :url => "/uploads/audio/:filename"
  validates_attachment_presence :file
  validates_attachment_content_type :file, :content_type => /\Aaudio\/.*\Z/

  after_initialize :init

  public

  def self.convert(id)
    audioFilename = Audio.find(id)
    audioFilename.status = Audio::STATUS_PROCESS
    audioFilename.save

    file_path = Rails.root.to_s + "/public/uploads/audio/" + audioFilename.file.original_filename
    cmd = "avconv -i #{file_path} -ac 2 -ab 64k #{Rails.root.to_s + "/public/uploads/audio/" + 'pirates_of_the_caribbean.ogg'}"

    if system cmd
      audioFilename.file.instance_write(:filename, audioFilename.file.original_filename + '.ogg' )
      audioFilename.status = Audio::STATUS_CONVERTED
      audioFilename.save
      FileUtils.rm file_path
    end
  end

  private

  def init
    self.status ||=Audio::STATUS_NEW
  end

end
