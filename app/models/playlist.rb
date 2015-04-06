class Playlist < ActiveRecord::Base
  has_many :audios, dependent: :destroy
end
