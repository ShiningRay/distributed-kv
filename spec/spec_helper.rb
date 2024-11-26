require 'rspec'
require 'rack/test'
require 'webmock/rspec'

ENV['RACK_ENV'] = 'test'

# 加载应用代码
require_relative '../lib/node'
require_relative '../lib/cluster_manager'
require_relative '../lib/storage'
require_relative '../lib/hash_ring'

RSpec.configure do |config|
  config.include Rack::Test::Methods
  
  config.before(:each) do
    # 清理测试环境
    WebMock.disable_net_connect!(allow_localhost: true)
    
    # 在测试中使用不同的端口
    @test_port = Random.rand(20000..30000)
  end

  config.after(:each) do
    WebMock.reset!
  end
end
