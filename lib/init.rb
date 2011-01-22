class TrackifoConfig
  attr_accessor :config, :db, :notifo, :tracker
  def initialize(yml_file)
    content = File.new(yml_file).read
    self.config = YAML::load(content)
    self.db = self.config['database']
    self.notifo = self.config['notifo']
    self.tracker = self.config['tracker']
  end
end

config = TrackifoConfig.new("config.yml")

DB = Sequel.mysql config.db['database'], :user => config.db['user'], :password => config.db['pass'], :host => config.db['host']
NOTIFO = Notifo.new(config.notifo['user'], config.notifo['token'])

Sequel::Model.raise_on_save_failure = false
