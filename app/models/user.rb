class User < ActiveRecord::Base
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable,
    :omniauthable, :omniauth_providers => [:facebook, :google_oauth2]

    has_many :mylists

    def my_songs
        sa = Array.new
        self.mylists.each do |ml|
            ml.mylist_songs.each do |s|
                s = s.song
                sa << s
            end
        end
        if sa.count == 0
            sa << Song.where.not(lowkey: nil).first(12)
        end
        sa
    end

    def self.from_omniauth(auth)
        where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
            user.email = auth.info.email
            user.password = Devise.friendly_token[0,20]
            user.name = auth.info.name   # assuming the user model has a name
            # user.image = auth.info.image # assuming the user model has an image
        end
    end

    def self.new_with_session(params, session)
        super.tap do |user|
            if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
                user.email = data["email"] # if user.email.blank?
            end
        end
    end

    def self.find_for_google_oauth2(access_token, signed_in_resource=nil)
        data = access_token.info
        user = User.where(:provider => access_token.provider, :uid => access_token.uid ).first
        if user
            return user
        else
            registered_user = User.where(:email => access_token.info.email).first
            if registered_user
                return registered_user
            else
                user = User.create(name: data["name"],
                provider:access_token.provider,
                email: data["email"],
                uid: access_token.uid ,
                password: Devise.friendly_token[0,20],
                )
            end
        end
    end
end
