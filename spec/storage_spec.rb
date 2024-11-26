require 'spec_helper'

RSpec.describe Storage do
  let(:cluster_manager) { instance_double('ClusterManager') }
  let(:ring) { instance_double('HashRing') }
  let(:local_port) { @test_port }
  let(:local_address) { "localhost:#{local_port}" }
  let(:storage) { Storage.new(cluster_manager) }

  before do
    allow(cluster_manager).to receive(:ring).and_return(ring)
    allow(cluster_manager).to receive(:local_address).and_return(local_address)
    allow(cluster_manager).to receive(:get_node_port).and_return(local_port)
    allow(cluster_manager).to receive(:subscribe).and_yield(:join, "newnode:#{local_port + 1}")
  end

  describe '#set' do
    context 'when key belongs to local node' do
      before do
        allow(ring).to receive(:get_node).with('test_key').and_return(local_address)
      end

      it 'stores the value locally' do
        expect(storage.set('test_key', 'test_value')).to eq('test_value')
        expect(storage.get('test_key')).to eq('test_value')
      end
    end

    context 'when key belongs to remote node' do
      let(:remote_port) { local_port + 1 }
      let(:remote_address) { "remote:#{remote_port}" }
      
      before do
        allow(ring).to receive(:get_node).with('test_key').and_return(remote_address)
        allow(cluster_manager).to receive(:get_node_port).with(remote_address).and_return(remote_port)
        
        stub_request(:post, "http://remote:#{remote_port}/set/test_key")
          .with(body: { value: 'test_value' }.to_json)
          .to_return(status: 200, body: 'test_value')
      end

      it 'forwards the request to the correct node' do
        expect(storage.set('test_key', 'test_value')).to eq('test_value')
      end
    end
  end

  describe '#get' do
    context 'when key belongs to local node' do
      before do
        allow(ring).to receive(:get_node).with('test_key').and_return(local_address)
        storage.set('test_key', 'test_value')
      end

      it 'retrieves the value locally' do
        expect(storage.get('test_key')).to eq('test_value')
      end
    end

    context 'when key belongs to remote node' do
      let(:remote_port) { local_port + 1 }
      let(:remote_address) { "remote:#{remote_port}" }
      
      before do
        allow(ring).to receive(:get_node).with('test_key').and_return(remote_address)
        allow(cluster_manager).to receive(:get_node_port).with(remote_address).and_return(remote_port)
        
        stub_request(:get, "http://remote:#{remote_port}/get/test_key")
          .to_return(status: 200, body: 'test_value')
      end

      it 'forwards the request to the correct node' do
        expect(storage.get('test_key')).to eq('test_value')
      end
    end
  end

  describe '#redistribute_data' do
    let(:data) { { 'key1' => 'value1', 'key2' => 'value2' } }
    let(:remote_port) { local_port + 1 }
    let(:remote_address) { "remote:#{remote_port}" }
    
    before do
      # 模拟一些初始数据
      storage.instance_variable_set(:@data, data.dup)
      
      # 模拟key1属于本地节点，key2属于远程节点
      allow(ring).to receive(:get_node).with('key1').and_return(local_address)
      allow(ring).to receive(:get_node).with('key2').and_return(remote_address)
      allow(cluster_manager).to receive(:get_node_port).with(remote_address).and_return(remote_port)
      
      # 模拟向远程节点发送数据
      stub_request(:post, "http://remote:#{remote_port}/set/key2")
        .with(body: { value: 'value2' }.to_json)
        .to_return(status: 200, body: 'value2')
    end

    it 'redistributes data when node ownership changes' do
      storage.send(:redistribute_data)
      # key1应该保留在本地，key2应该被删除（因为已经转移到远程节点）
      expect(storage.instance_variable_get(:@data)).to eq({ 'key1' => 'value1' })
    end
  end
end
