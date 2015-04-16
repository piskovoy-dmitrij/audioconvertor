class User < ActiveRecord::Base
  extend FriendlyId

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:facebook, :twitter, :gplus]

  validates_uniqueness_of :username

  has_many :audios, dependent: :destroy

  has_many :friendships, dependent: :destroy
  has_many :friends, :through => :friendships, :source => :friend
  has_many :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id"
  has_many :followers, :through => :inverse_friendships, :source => :user

  has_many :authentications, :foreign_key => "user_id"

  friendly_id :slug_candidates, use: [:slugged, :history]

  paginates_per 15

  include Searchable

  settings analysis: {
               filter: {
                   ngram_filter: {
                       type: 'nGram',
                       min_gram: 2,
                       max_gram: 50
                   }
               },
               analyzer: {
                   index_ngram_analyzer: {
                       type: 'custom',
                       tokenizer: 'standard',
                       filter: ['lowercase', 'ngram_filter']
                   },
                   search_ngram_analyzer: {
                       type: 'custom',
                       tokenizer: 'standard',
                       filter: ['lowercase']
                   }
               }
           } do
    mapping do
      indexes :name, type: 'string', index_analyzer: 'index_ngram_analyzer', search_analyzer: 'search_ngram_analyzer'
    end
  end

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

  def friends_list
    friends.where('is_confirmed = true')
  end

  def requests
    friends.where('is_confirmed = false')
  end

  def invites
    followers.where('is_confirmed = false')
  end

  def me?(user)
    self.id == user.id
  end

  def invite(user)
    if can_become_friend_with?(user)
      Friendship.new({friend: user, user: self}).save
    else
      false
    end
  end

  def confirm_friendship(user)
    friendship = get_inverse_friendship(user)
    if friendship.nil?
      false
    else
      friendship.update_attribute(:is_confirmed, true)
    end
  end

  def remove_friendship(user)
    friendship = get_confiremd_friendship(user)
    if friendship.nil?
      false
    else
      friendship.destroy
    end
  end

  def cancel_friendship(user)
    friendship = get_friendship(user)
    if friendship.nil?
      false
    else
      friendship.destroy
    end
  end

  def total_friends
    friends_list.count
  end

  def total_invites
    invites.count
  end

  def total_requests
    requests.count
  end

  def friend_with?(user)
    friends_list.include?(user)
  end

  def connected_with?(user)
    friends.include?(user)
  end

  def get_inverse_friendship(user)
    inverse_friendships.where({is_confirmed: false, user: user}).first
  end

  def get_friendship(user)
    friendships.where({is_confirmed: false, friend: user}).first
  end

  def get_confiremd_friendship(user)
    friendships.where({is_confirmed: true, friend: user}).first
  end

  def request_friendship?(user)
    invites.include?(user)
  end

  def can_become_friend_with?(user)
    !me?(user) && (!friend_with?(user) || request_friendship?(user))
  end

  def as_indexed_json(options={})
    self.as_json(
        only: [:id, :name],
        include: {
            friendships: {only: [:friend_id, :is_confirmed]},
            inverse_friendships: {only: [:user_id, :is_confirmed]},
        }
    )
  end

  def self.set_needed_filters(query, options)

    @search_definition[:highlight][:fields] = {
        name: {}
    }

    unless query.blank?
      @search_definition[:query] = {
          bool: {
              should: [
                  {
                      match: {
                          name: query
                      }
                  }
              ]
          }
      }
    end

    @search_definition[:sort] = {name: 'asc'}

    if options[:friendship]
      f = {term: {'friendships.friend_id' => options[:friendship]}}

      __set_filters.(:friendships, f)
      options.delete(:friendship)
    end

    options.delete(:name)

    options
  end
end
