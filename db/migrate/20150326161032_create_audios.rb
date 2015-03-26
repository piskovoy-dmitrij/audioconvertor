class CreateAudios < ActiveRecord::Migration
  def change
    create_table :audios do |t|
      t.string :title
      t.string :path
      t.string :status
      t.integer :user_id

      t.timestamps
    end

    add_index :audios, :user_id
  end
end
