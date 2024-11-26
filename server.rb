# 设置环境变量
ENV['SWIM_PORT'] ||= ARGV[0] || '9999'
ENV['HTTP_PORT'] ||= ARGV[1] || '8888'
ENV['SEEDS'] ||= ARGV[2] || ''
ENV['PRIMARY'] ||= ARGV[3] || 'false'

require_relative 'lib/node'

# 配置节点
Node.setup(
  ENV['SWIM_PORT'].to_i,
  ENV['HTTP_PORT'].to_i,
  ENV['SEEDS'].split(',').reject(&:empty?)
)

# 启动服务器
Node.run! host: '0.0.0.0'
