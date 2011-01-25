require File.dirname(__FILE__) + '/spec_helper'

describe "Trackifo" do
  include Rack::Test::Methods

  def app
    @app ||= Trackifo::Application
  end

  it "should respond to /" do
    get '/'
    last_response.should be_ok
  end

  it "should return 404 when page cannot be found" do
    get '/404'
    last_response.status.should == 404
  end

  it "should create session when login and redirect back to home" do
    User.new(:email => "daviscabral@foo.com", :password => "abc123").save
    post '/login', :email => "daviscabral@foo.com", :password => "12345"
    last_response.status.should == 302
    session['user_id'].should == nil

    post '/login', :email => "daviscabral@foo.com", :password => "abc123"
    last_response.status.should == 302
    session['user_id'].should == User[:email => 'daviscabral@foo.com'].id
  end

  describe "Logged in actions" do
    before :each do
      session['user_id'] = 1
    end

    it "should destroy session" do
      get '/bye'
      last_response.should be_ok
      session['user_id'].should == nil
    end

    it "should create a project" do

    end
  end
end
