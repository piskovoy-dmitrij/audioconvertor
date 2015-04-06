class User < ActiveRecord::Base
  extend FriendlyId

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:facebook, :twitter, :vkontakte, :gplus]

  validates_uniqueness_of :username

  has_many :audios, dependent: :destroy

  has_many :friendships
  has_many :all_friends, :through => :friendships, :source => :friend
  has_many :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id"
  has_many :all_followers, :through => :inverse_friendships, :source => :user

  has_many :authentications, :foreign_key => "user_id"

  friendly_id :slug_candidates, use: [:slugged, :history]

  self.friendly_id_config.slug_column = 'username'
  self.friendly_id_config.sequence_separator = '.'

  def self.from_omniauth(auth)
    authorization = Authorization.where(:provider => auth.provider, :uid => auth.uid.to_s, :token => auth.credentials.token, :secret => auth.credentials.secret).first_or_initialize

    user_email = auth.info.email.to_s

    if authorization.user.blank?
      if user_email.blank?
        user = User.where("#{auth.provider}_uid = ?", auth.uid.to_s).first
      else
        user = User.where("email = ?", user_email).first
      end

      if user.blank?
        user = User.new do
          def email_required?
            false
          end

          # def password_required?
          #   false
          # end
        end

        user.email = user_email
        user["#{auth.provider}_uid"] = auth.uid.to_s
        user.password = Devise.friendly_token
        user.name = auth.info.name

        if auth.extra.raw_info.nickname
          username = auth.extra.raw_info.nickname.to_s
        elsif auth.info.nickname
          username = auth.info.nickname
        else
          username = ''
        end

        user.username = username

        if auth.extra.raw_info.bdate
          birth_date = Date.strptime(auth.extra.raw_info.bdate, "%d.%m.%Y").to_s
        elsif auth.extra.raw_info.birthday
          birth_date = Date.strptime(auth.extra.raw_info.birthday, "%m/%d/%Y")
        else
          birth_date = ''
        end

        user.birth_date = birth_date

        user.save
      end

      authorization.user_id = user.id
      authorization.save
    end

    authorization.user
  end

  def slug_candidates
    self.username
    self.name.to_slug.normalize!({:transliterations => [:russian, :latin]}) if self.username.blank?
  end

  def should_generate_new_friendly_id?
    self.username.blank?
  end

  def normalize_friendly_id(string)
    super.downcase.gsub(self.friendly_id_config.defaults[:sequence_separator], self.friendly_id_config.sequence_separator)
  end
end
