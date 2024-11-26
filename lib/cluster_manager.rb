require 'hash_ring'
require 'concurrent'
require_relative 'colored_logger'
require_relative 'swim_node'

class ClusterManager
  attr_reader :ring, :local_address

  def initialize(host, seeds, swim_port, http_port)
    @local_address = "#{host}:#{http_port}"
    @logger = ColoredLogger.create("ClusterManager[#{@local_address}]")
    
    # 初始化一致性哈希环
    @ring = HashRing.new([@local_address])
    @node_ports = Concurrent::Map.new
    @node_ports[@local_address] = http_port

    # 初始化SWIM节点
    @swim_node = SwimNode.new(host, swim_port, http_port, seeds)
    
    # 订阅节点变更
    @swim_node.subscribe do |event, member|
      case event
      when :join
        handle_member_join(member)
      when :leave
        handle_member_leave(member)
      end
    end
  end

  def get_node_port(node_address)
    @node_ports[node_address]
  end

  private

  def handle_member_join(node_address)
    return if node_address == @local_address
    
    host, port = node_address.split(':')
    @node_ports[node_address] = port.to_i
    
    @logger.info "Node joined: #{node_address}"
    @ring.add_node(node_address)
  end

  def handle_member_leave(node_address)
    return unless node_address
    
    @logger.info "Node left: #{node_address}"
    @ring.remove_node(node_address)
    @node_ports.delete(node_address)
  end
end
