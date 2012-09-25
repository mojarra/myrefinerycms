require 'devise'
require 'friendly_id'

module Refinery
  class User < Refinery::Core::BaseModel
    self.table_name = "#{Refinery::Core.config.table_prefix}users"

    extend FriendlyId

    belongs_to :role

    has_many :plugins, :class_name => "UserPlugin", :order => "position ASC", :dependent => :destroy
    friendly_id :username

    # Include default devise modules. Others available are:
    # :token_authenticatable, :confirmable, :lockable and :timeoutable
    if self.respond_to?(:devise)
      devise :database_authenticatable, :registerable, :recoverable, :rememberable,
             :trackable, :validatable, :authentication_keys => [:login]
    end

    # Setup accessible (or protected) attributes for your model
    # :login is a virtual attribute for authenticating by either username or email
    # This is in addition to a real persisted field like 'username'
    attr_accessor :login
    attr_accessible :email, :password, :password_confirmation, :remember_me, :username, :plugins, :login

    validates :username, :presence => true, :uniqueness => true
    before_validation :downcase_username

    class << self
      # Find user by email or username.
      # https://github.com/plataformatec/devise/wiki/How-To:-Allow-users-to-sign_in-using-their-username-or-email-address
      def find_for_database_authentication(conditions)
        value = conditions[authentication_keys.first]
        where(["username = :value OR email = :value", { :value => value }]).first
      end
    end

    def plugins=(plugin_names)
      if persisted? # don't add plugins when the user_id is nil.
        UserPlugin.delete_all(:user_id => id)

        plugin_names.each_with_index do |plugin_name, index|
          plugins.create(:name => plugin_name, :position => index) if plugin_name.is_a?(String)
        end
      end
    end

    def authorized_plugins
      plugins.collect(&:name) | ::Refinery::Plugins.always_allowed.names
    end

    def can_delete?(user_to_delete = self)
      user_to_delete.persisted? &&
        !user_to_delete.has_role?(:superuser) &&
        id != user_to_delete.id
    end

    def can_edit?(user_to_edit = self)
      user_to_edit.persisted? && (
        user_to_edit == self ||
        self.has_role?(:superuser)
      )
    end

    def has_role?(title)
      raise ArgumentException, "Role should be the title of the role not a role object." if title.is_a?(::Refinery::Role)
      if title.to_s.camelize == "Refinery"
        true
      else
        role.blank? ? false : role.title == title.to_s.camelize
      end
    end

    def create_first
      if valid?
        # first we need to save user
        save
        # set superuser role if there are no other users
        self.role = ::Refinery::Role[:superuser] if ::Refinery::User.count == 1
        # add plugins
        self.plugins = Refinery::Plugins.registered.in_menu.names
        save
      end

      # return true/false based on validations
      valid?
    end

    def to_s
      username.to_s
    end

    def to_param
      to_s.parameterize
    end

    private
    # To ensure uniqueness without case sensitivity we first downcase the username.
    # We do this here and not in SQL is that it will otherwise bypass indexes using LOWER:
    # SELECT 1 FROM "refinery_users" WHERE LOWER("refinery_users"."username") = LOWER('UsErNAME') LIMIT 1
    def downcase_username
      self.username = self.username.downcase if self.username?
    end

  end
end
