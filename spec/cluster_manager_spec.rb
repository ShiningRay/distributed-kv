require 'spec_helper'

RSpec.describe ClusterManager do
  let(:local_address) { 'localhost' }
  let(:swim_port) { @test_port }
  let(:http_port) { @test_port + 1 }
  let(:seeds) { ['seed1:9999', 'seed2:9999'] }
  let(:cluster_manager) { ClusterManager.new(local_address, seeds, swim_port, http_port) }

  before(:all) do
    @test_port = 10_000 + rand(1000)
  end

  describe '#initialize' do
    it 'initializes with correct configuration' do
      expect(cluster_manager.local_address).to eq("#{local_address}:#{http_port}")
      expect(cluster_manager.ring.nodes).to include("#{local_address}:#{http_port}")
    end
  end

  describe '#handle_member_join' do
    let(:new_host) { 'newnode' }
    let(:custom_state) { { http_port: http_port + 1 } }

    it 'adds new member to the ring' do
      cluster_manager.send(:handle_member_join, new_host, custom_state)
      expect(cluster_manager.ring.nodes).to include("#{new_host}:#{http_port + 1}")
    end

    it 'notifies subscribers about new member' do
      events = []
      cluster_manager.subscribe { |event, member| events << [event, member] }
      
      cluster_manager.send(:handle_member_join, new_host, custom_state)
      expect(events).to include([:join, "#{new_host}:#{http_port + 1}"])
    end

    it 'ignores join events from self' do
      cluster_manager.send(:handle_member_join, local_address, { http_port: http_port })
      # 环中应该只有一个本地节点
      expect(cluster_manager.ring.nodes.count).to eq(1)
    end
  end

  describe '#handle_member_leave' do
    let(:leaving_host) { 'leavingnode' }
    
    before do
      # 先添加一个节点
      cluster_manager.send(:handle_member_join, leaving_host, { http_port: http_port + 2 })
    end

    it 'removes member from the ring' do
      cluster_manager.send(:handle_member_leave, leaving_host)
      expect(cluster_manager.ring.nodes).not_to include("#{leaving_host}:#{http_port + 2}")
    end

    it 'notifies subscribers about leaving member' do
      events = []
      cluster_manager.subscribe { |event, member| events << [event, member] }
      
      cluster_manager.send(:handle_member_leave, leaving_host)
      expect(events).to include([:leave, "#{leaving_host}:#{http_port + 2}"])
    end
  end

  describe '#get_node_port' do
    let(:node_address) { "testnode:#{http_port + 3}" }
    
    before do
      cluster_manager.send(:handle_member_join, 'testnode', { http_port: http_port + 3 })
    end

    it 'returns correct port for node' do
      expect(cluster_manager.get_node_port(node_address)).to eq(http_port + 3)
    end

    it 'returns nil for unknown node' do
      expect(cluster_manager.get_node_port('unknown:8888')).to be_nil
    end
  end
end
