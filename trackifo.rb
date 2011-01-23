require 'rubygems'
require 'sinatra/base'
require 'yaml'
require 'haml'
require 'sequel'
require 'mysql'
require 'nokogiri'
require 'json'
require 'httparty'
require 'titleize'

configure :development do |config|
  require "sinatra/reloader"
  config.also_reload "lib/*.rb"
end

require 'lib/notifo'
require 'lib/init'
require 'lib/models'
require 'rack-flash'

module Trackifo
  class Application < Sinatra::Base
    configure :development do |config|
      register Sinatra::Reloader
    end

    def redirect_if_not_logged_in
      unless session['user_id']
        redirect '/'
      end
    end

    set :public, File.dirname(__FILE__) + '/public'
    enable :sessions
    use Rack::Flash

    get '/' do
      session['user_id'] ||= nil
      if session['user_id']
        @projects = Project.filter({:user_id => session['user_id']})
      end
      haml :index
    end

    post '/login' do
      if user = User.auth(params[:email], params[:password])
        session['user_id'] = user.id
      else
        flash[:notice] = "Invalid user/pass! Try it again! (y)"
      end
      redirect '/'
    end

    get '/bye' do
      session['user_id'] = nil
      haml :bye
    end

    post '/project/create' do
      redirect_if_not_logged_in
      project = Project.new(params)
      project.user_id = session['user_id']
      if project.save
        flash[:notice] = "Yeah! The party is here! \o/"
      else
        flash[:notice] = "Something wrong! Try it again! :("
      end
      redirect '/'
    end

    post '/create' do
      user = User.new(params)
      if user.save
        session['user_id'] = user.id
        flash[:notice] = "Welcome aboard!"
        redirect '/'
      else
        flash[:notice] = "Something is wrong: <br /><ul><li>"
        flash[:notice] << user.errors.full_messages.join("</li><li>") << "</li></ul>"
        haml :index
      end
    end

    get '/unsubscribe/:project_id/u/:subscription_id' do
      redirect_if_not_logged_in
      project = Project[:id => params[:project_id]]
      subscription = project.subscriptions.filter(:id => params[:subscription_id])
      if subscription.destroy
        flash[:notice] = "User unsubscribed"
      else
        flash[:notice] = "Something wrong, user was not removed"
      end
      redirect "/project/#{project.id}"
    end

    post '/subscribe/:project_id' do
      redirect_if_not_logged_in
      project = Project[:id => params[:project_id]]
      subscription = Subscription.new(:username => params[:username], :project_id => project.id)
      if subscription.save
        response = NOTIFO.subscribe_user(subscription.username)
        if response['response_code'] == 2201
          subscription.status = 'completed'
          flash[:notice] = "User subscribed! Should receive messages right now!"
        else
          subscription.status = 'pending'
          flash[:notice] = "Something wrong. Maybe this user is already subscribed to the service."
        end
        subscription.save
      end
      redirect "/project/#{project.id}"
    end

    post '/notify/:project_id' do
      project = Project[:id => params[:project_id]]
      if project
        subscriptions = Subscription.filter(:project_id => project.id)
        activity = Nokogiri::parse(request.body.read)
        title = activity.xpath("//activity/event_type").first.children.text.gsub("_", " ").titleize
        msg = activity.xpath("//activity/description").first.children.text
        id = activity.xpath("//activity/stories").first.xpath("//id").first.children.text
        uri = activity.xpath("//activity/stories").first.xpath("//url").first.children.text
        content_type :json
        response = []
        subscriptions.each do |subscription|
          response << [subscription.username, "[#{project.name}] #{msg}", title, uri]
          response << NOTIFO.send_notification(subscription.username, "[#{project.name}] #{msg}", title, uri, "Trackifo")
        end
        response.to_json
      end
    end

    get '/project/:id' do
      redirect_if_not_logged_in
      @project = Project[:id => params[:id], :user_id => session['user_id']]
      @subscriptions = @project.subscriptions
      haml :project
    end

    error 400..510 do
      begin
        File.read(File.join('public', '500.html'))
      rescue Exception => e
        'Boom'
      end
    end

    error 404 do
      begin
        File.read(File.join('public', '404.html'))
      rescue
        'This is nowhere to be found'
      end
    end

  end
end
