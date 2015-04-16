class CreateAudiosPlaylists < ActiveRecord::Migration
  def change
    create_table :audios_playlists, id: false do |t|
      t.integer :playlist_id
      t.integer :audio_id
    end

    add_index :audios_playlists, :playlist_id
    add_index :audios_playlists, :audio_id
  end
end
