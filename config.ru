require './lib/node'

Node.set :swim_port, ENV['SWIM_PORT']&.to_i || 7946
Node.set :http_port, ENV['HTTP_PORT']&.to_i || 4567
Node.set :seeds, (ENV['SEEDS'] || '').split(',').reject(&:empty?)
Node.set :primary, ENV['PRIMARY'] == 'true'

run Node
