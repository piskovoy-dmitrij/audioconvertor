class AddAudioAttachment < ActiveRecord::Migration
  def change
    add_attachment :audios, :file
  end
end
