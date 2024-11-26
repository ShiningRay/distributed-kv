#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'optparse'
require 'faker'
require_relative '../lib/colored_logger'

$logger = ColoredLogger.create("DataGenerator")

options = {
  host: 'localhost',
  port: ARGV[0] ? ARGV[0].to_i : 6000,
  count: 100,
  batch_size: 10
}

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-H", "--host HOST", "Host to connect to (default: #{options[:host]})") do |h|
    options[:host] = h
  end

  opts.on("-p", "--port PORT", Integer, "Port to connect to (default: #{options[:port]})") do |p|
    options[:port] = p
  end

  opts.on("-n", "--count COUNT", Integer, "Number of records to insert (default: #{options[:count]})") do |n|
    options[:count] = n
  end

  opts.on("-b", "--batch-size SIZE", Integer, "Batch size for insertion (default: #{options[:batch_size]})") do |b|
    options[:batch_size] = b
  end

  opts.on("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

def insert_data(host, port, key, value)
  uri = URI("http://#{host}:#{port}/set")
  $logger.debug "Inserting data: #{uri}, key=#{key}"
  response = Net::HTTP.post_form(uri, {'key' => key, 'value' => value})
  result = JSON.parse(response.body)
  $logger.debug "Response: #{result.inspect}"
  result
rescue => e
  $logger.error "Error inserting #{key}: #{e.message}"
  nil
end

$logger.info "Starting data insertion..."
$logger.info "Target: http://#{options[:host]}:#{options[:port]}"
$logger.info "Total records: #{options[:count]}"
$logger.info "Batch size: #{options[:batch_size]}"

success_count = 0
start_time = Time.now

options[:count].times.each_slice(options[:batch_size]) do |batch|
  $logger.info "Processing batch of #{batch.size} records..."
  threads = batch.map do |i|
    Thread.new do
      key = "key_#{Faker::Internet.uuid}"
      value = {
        name: Faker::Name.name,
        email: Faker::Internet.email,
        address: Faker::Address.full_address,
        company: Faker::Company.name,
        created_at: Time.now.to_i
      }.to_json

      result = insert_data(options[:host], options[:port], key, value)
      if result && result['success']
        success_count += 1
        print '.'
      else
        print 'x'
      end
    end
  end

  threads.each(&:join)
  $logger.info "Batch completed. Current success count: #{success_count}"
end

end_time = Time.now
duration = end_time - start_time

$logger.info "\nInsertion completed!"
$logger.info "Successful insertions: #{success_count}/#{options[:count]}"
$logger.info "Time taken: #{duration.round(2)} seconds"
$logger.info "Average speed: #{(options[:count] / duration).round(2)} ops/sec"
