require 'concurrent'
require 'json'
require 'net/http'
require_relative 'colored_logger'

class Storage
  def initialize(cluster_manager)
    @cluster_manager = cluster_manager
    @data = Concurrent::Map.new
    @logger = ColoredLogger.create("Storage[#{cluster_manager.local_address}]")
  end

  def set(key, value)
    target_node = @cluster_manager.ring.get_node(key)
    @logger.info "SET: key=#{key}, target=#{target_node}, local=#{@cluster_manager.local_address}"
    
    if target_node == @cluster_manager.local_address
      store_locally(key, value)
    else
      forward_set(target_node, key, value)
    end
  end

  def get(key)
    target_node = @cluster_manager.ring.get_node(key)
    @logger.info "GET: key=#{key}, target=#{target_node}, local=#{@cluster_manager.local_address}"
    
    if target_node == @cluster_manager.local_address
      read_locally(key)
    else
      forward_get(target_node, key)
    end
  end

  def redistribute_data
    @logger.info "Redistributing data..."
    current_data = @data.each_pair.to_h
    
    current_data.each do |key, value|
      target_node = @cluster_manager.ring.get_node(key)
      
      if target_node != @cluster_manager.local_address
        @logger.info "Moving key #{key} to #{target_node}"
        if forward_set(target_node, key, value)
          @data.delete(key)
        end
      end
    end
  end

  private

  def store_locally(key, value)
    @logger.debug "Storing locally: key=#{key}"
    @data[key] = value
    { success: true, value: value }
  end

  def read_locally(key)
    @logger.debug "Reading locally: key=#{key}"
    value = @data[key]
    { success: true, value: value }
  end

  def forward_set(node, key, value)
    host, port = node.split(':')
    uri = URI("http://#{host}:#{port}/set")
    
    make_request(uri) do |http|
      request = Net::HTTP::Post.new(uri)
      request.content_type = 'application/json'
      request.body = { key: key, value: value }.to_json
      http.request(request)
    end
  end

  def forward_get(node, key)
    host, port = node.split(':')
    uri = URI("http://#{host}:#{port}/get?key=#{key}")
    
    make_request(uri) do |http|
      http.get(uri)
    end
  end

  def make_request(uri)
    response = Net::HTTP.start(uri.host, uri.port) do |http|
      http.read_timeout = 5
      http.open_timeout = 2
      yield(http)
    end
    
    JSON.parse(response.body)
  rescue => e
    @logger.error "Request failed: #{e.message}"
    { success: false, error: e.message }
  end
end
