require 'swim'
require 'json'
require_relative 'colored_logger'

class SwimNode
  attr_reader :local_address, :swim_port, :http_port

  def initialize(host, swim_port, http_port, seeds = [])
    @host = host
    @swim_port = swim_port
    @http_port = http_port
    @local_address = "#{host}:#{http_port}"
    @logger = ColoredLogger.create("SwimNode[#{@local_address}]")
    @subscribers = []
    
    setup_swim(host, seeds)
  end

  def subscribe(&block)
    @subscribers << block
  end

  private

  def setup_swim(host, seeds)
    @logger.info "Setting up SWIM: host=#{host}, seeds=#{seeds.join(',')}, port=#{swim_port}"
    
    @swim = Swim::Protocol.new(
      host,
      @swim_port,
      seeds
    )

    # 订阅成员状态变化事件
    @swim.directory.subscribe(self)

    # 设置自定义状态
    @swim.directory.current_node.metadata = { http_port: @http_port }

    # 启动SWIM协议
    Thread.new { @swim.start }.abort_on_exception = true
  end

  # Wisper事件处理方法
  def member_joined(member)
    @logger.debug "Member joined: #{member.address}"
    notify_subscribers(:join, member_address(member))
  end

  def member_left(member)
    @logger.debug "Member left: #{member.address}"
    notify_subscribers(:leave, member_address(member))
  end

  def member_address(member)
    return nil unless member.metadata && member.metadata[:http_port]
    "#{member.host}:#{member.metadata[:http_port]}"
  end

  def notify_subscribers(event, member)
    return unless member
    @subscribers.each do |subscriber|
      begin
        subscriber.call(event, member)
      rescue => e
        @logger.error "Subscriber error: #{e.message}"
      end
    end
  end
end
