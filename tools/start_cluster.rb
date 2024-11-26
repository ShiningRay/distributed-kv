#!/usr/bin/env ruby

require 'optparse'
require 'fileutils'

options = {
  nodes: 3,
  base_swim_port: 9999,
  base_http_port: 8888,
  log_dir: 'logs'
}

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-n", "--nodes COUNT", Integer, "Number of nodes to start (default: #{options[:nodes]})") do |n|
    options[:nodes] = n
  end

  opts.on("--swim-port PORT", Integer, "Base SWIM port (default: #{options[:base_swim_port]})") do |p|
    options[:base_swim_port] = p
  end

  opts.on("--http-port PORT", Integer, "Base HTTP port (default: #{options[:base_http_port]})") do |p|
    options[:base_http_port] = p
  end

  opts.on("--log-dir DIR", "Directory for log files (default: #{options[:log_dir]})") do |d|
    options[:log_dir] = d
  end

  opts.on("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

# 创建日志目录
FileUtils.mkdir_p(options[:log_dir])

# 清理旧的进程ID文件
FileUtils.rm_f(Dir.glob("#{options[:log_dir]}/*.pid"))

def start_node(node_id, swim_port, http_port, seed_node, log_dir)
  log_file = File.join(log_dir, "node_#{node_id}.log")
  pid_file = File.join(log_dir, "node_#{node_id}.pid")
  
  cmd = if seed_node
    "bundle exec ruby server.rb #{swim_port} #{http_port} #{seed_node}"
  else
    "bundle exec ruby server.rb #{swim_port} #{http_port}"
  end

  pid = spawn(cmd, out: log_file, err: [:child, :out])
  File.write(pid_file, pid)
  
  puts "Started node #{node_id}:"
  puts "  SWIM port: #{swim_port}"
  puts "  HTTP port: #{http_port}"
  puts "  PID: #{pid}"
  puts "  Log: #{log_file}"
  puts "  #{seed_node ? "Seed: #{seed_node}" : "Primary node"}"
  puts
  
  pid
end

puts "Starting #{options[:nodes]} nodes..."
puts

# 启动第一个节点（主节点）
first_node = start_node(
  1,
  options[:base_swim_port],
  options[:base_http_port],
  nil,
  options[:log_dir]
)

# 等待主节点启动
sleep 2

# 启动其他节点
seed_node = "localhost:#{options[:base_swim_port]}"
(2..options[:nodes]).each do |i|
  start_node(
    i,
    options[:base_swim_port] - (i-1),
    options[:base_http_port] - (i-1),
    seed_node,
    options[:log_dir]
  )
  # 给每个节点一点启动时间
  sleep 1
end

puts "\nAll nodes started! To stop the cluster, run:"
puts "kill `cat #{options[:log_dir]}/*.pid`"
