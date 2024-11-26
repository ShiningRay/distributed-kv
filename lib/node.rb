require 'sinatra/base'
require 'json'
require_relative 'cluster_manager'
require_relative 'storage'
require_relative 'colored_logger'

class Node < Sinatra::Base
  configure do
    set :bind, '0.0.0.0'
    enable :logging
  end

  class << self
    attr_accessor :swim_port, :http_port, :seeds
  end

  def self.setup(swim_port, http_port, seeds = nil)
    set :port, http_port
    @swim_port = swim_port
    @http_port = http_port
    @seeds = seeds || []
  end

  def initialize(app = nil)
    super(app)
    
    @logger = ColoredLogger.create("Node[localhost:#{self.class.http_port}]")
    @logger.info "Initializing node: swim_port=#{self.class.swim_port}, http_port=#{self.class.http_port}, seeds=#{self.class.seeds}"

    @cluster_manager = ClusterManager.new(
      'localhost',
      self.class.seeds,
      self.class.swim_port,
      self.class.http_port
    )
    
    @storage = Storage.new(@cluster_manager)
  end

  before do
    content_type :json
  end

  post '/set' do
    payload = JSON.parse(request.body.read)
    result = @storage.set(payload['key'], payload['value'])
    result.to_json
  end

  get '/get' do
    result = @storage.get(params['key'])
    result.to_json
  end

  get '/status' do
    {
      address: @cluster_manager.local_address,
      port: settings.port,
      status: 'ok'
    }.to_json
  end

  get '/cluster/info' do
    {
      local_address: @cluster_manager.local_address,
      swim_port: self.class.swim_port,
      http_port: self.class.http_port,
      seeds: self.class.seeds
    }.to_json
  end
end
