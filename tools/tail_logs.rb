#!/usr/bin/env ruby

require 'optparse'
require 'fileutils'

options = {
  log_dir: 'logs',
  lines: 10
}

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("--log-dir DIR", "Directory containing log files (default: #{options[:log_dir]})") do |d|
    options[:log_dir] = d
  end

  opts.on("-n", "--lines COUNT", Integer, "Number of lines to show initially (default: #{options[:lines]})") do |n|
    options[:lines] = n
  end

  opts.on("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

# 检查日志目录是否存在
unless Dir.exist?(options[:log_dir])
  puts "Error: Log directory '#{options[:log_dir]}' does not exist"
  exit 1
end

# 获取所有日志文件
log_files = Dir.glob(File.join(options[:log_dir], "node_*.log"))

if log_files.empty?
  puts "No log files found in '#{options[:log_dir]}'"
  exit 1
end

puts "Monitoring #{log_files.length} log files..."
puts "Press Ctrl+C to stop"
puts

# 构建tail命令
cmd = [
  "tail",
  "-n", options[:lines].to_s,
  "-f",
  *log_files
]

# 执行tail命令
exec(*cmd)
