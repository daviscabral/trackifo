class Notifo
  include HTTParty
  base_uri 'https://api.notifo.com/v1'

  def initialize(username, token)
    @basic_auth = {:username => username, :password => token}
  end

  def subscribe_user(username)
    params = { :body => {:username => username}, :basic_auth => @basic_auth }
    self.class.post("/subscribe_user", params)
  end

  def send_notification(to, msg, title=nil, uri=nil, label=nil)
    params = { :body => {:to => to, :msg => msg, :label => label, :title => title, :uri => uri}, :basic_auth => @basic_auth }
    self.class.post('/send_notification', params)
  end
end
