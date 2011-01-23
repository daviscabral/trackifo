require 'rubygems'
require 'sequel'
require 'mysql'

class User < Sequel::Model
  EMAIL_REGEXP = /^\S+@\S+\.\w{2,}$/
  one_to_many :projects

  plugin :validation_helpers
  attr_accessor :password
  def validate
    super
    validates_presence [:email, :password]
    validates_unique :email
    validates_format EMAIL_REGEXP, :email, :message => "is not a valid email address"
    validates_min_length 6, :password
  end

  def before_create
    encrypt_password
    super
  end

  def self.auth(email, password)
    u = User[:email => email]
    u && u.authenticated?(password) ? u : nil
  end

  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def encrypt_password
    return if password.blank?
    self.salt ||= Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--")
    self.crypted_password = encrypt(password)
  end

  def projects
    Project.filter(:user_id => id)
  end
end

class Project < Sequel::Model
  many_to_one :user
  many_to_many :subscriptions

  plugin :validation_helpers
  def validate
    super
    validates_presence [:name, :tracker_id]
    validates_unique :tracker_id
  end

  def subscriptions
    Subscription.filter(:project_id => id)
  end
end

class Subscription < Sequel::Model
  many_to_many :projects
end
