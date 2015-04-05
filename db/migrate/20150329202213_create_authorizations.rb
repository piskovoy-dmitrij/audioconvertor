class CreateAuthorizations < ActiveRecord::Migration
  def change
    create_table :authorizations, id: false do |t|
      t.integer :user_id
      t.string :provider
      t.string :uid
      t.string :token
      t.string :secret
      t.datetime :created_at
    end

    add_index :authorizations, [:provider, :uid, :token, :secret]
  end
end
