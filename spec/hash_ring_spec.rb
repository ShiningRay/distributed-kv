require 'spec_helper'

RSpec.describe HashRing do
  let(:nodes) { ['node1:8888', 'node2:8888', 'node3:8888'] }
  let(:ring) { HashRing.new(nodes) }

  describe '#initialize' do
    it 'creates a ring with the given nodes' do
      expect(ring.nodes).to match_array(nodes)
    end
  end

  describe '#add_node' do
    it 'adds a new node to the ring' do
      ring.add_node('node4:8888')
      expect(ring.nodes).to include('node4:8888')
    end
  end

  describe '#remove_node' do
    it 'removes a node from the ring' do
      ring.remove_node('node1:8888')
      expect(ring.nodes).not_to include('node1:8888')
    end
  end

  describe '#get_node' do
    it 'returns a node for a given key' do
      node = ring.get_node('test_key')
      expect(nodes).to include(node)
    end

    it 'consistently returns the same node for the same key' do
      node1 = ring.get_node('test_key')
      node2 = ring.get_node('test_key')
      expect(node1).to eq(node2)
    end

    it 'distributes keys relatively evenly' do
      distribution = {}
      1000.times do |i|
        node = ring.get_node("key#{i}")
        distribution[node] ||= 0
        distribution[node] += 1
      end

      # 检查分布是否相对均匀（允许20%的偏差）
      avg = 1000.0 / nodes.length
      distribution.values.each do |count|
        expect(count).to be_within(avg * 0.2).of(avg)
      end
    end
  end
end
