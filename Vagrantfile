require "net/ssh"

module Net::SSH
  class << self
    alias_method :old_start, :start

    def start(host, username, opts)
      opts[:keys_only] = false
      self.old_start(host, username, opts)
    end
  end
end

Vagrant.configure("2") do |config|
  module Vagrant
    module Util
      class Platform
        class << self
          def solaris?
            true
          end
        end
      end
		end
	end
end

shome=File.expand_path("..", __FILE__)

ci_script = "#{shome}/script/cloud-init-bootstrap"

Vagrant.configure("2") do |config|
  config.ssh.shell = "bash"
  config.ssh.username = "ubuntu"
  config.ssh.forward_agent = true
  config.ssh.insert_key = false

  config.vm.provider "virtualbox" do |v, override|
    override.vm.box = ENV['BASEBOX_NAME']
    override.vm.network "private_network", ip: '172.28.128.10', nic_type: 'virtio'

    override.vm.synced_folder ENV['HOME'], '/vagrant', disabled: true
    override.vm.synced_folder '/data', '/data', type: "nfs"
    override.vm.synced_folder '/config', '/config', type: "nfs"

    override.vm.provision "shell", path: ci_script, args: [], privileged: true

    v.linked_clone = true
    v.memory = 1024
    v.cpus = 2

    v.customize [ 'modifyvm', :id, '--nictype1', 'virtio' ]
    v.customize [ 'modifyvm', :id, '--paravirtprovider', 'kvm' ]
    v.customize [ 'modifyvm', :id, '--cableconnected1', 'on' ]
    v.customize [ 'modifyvm', :id, '--cableconnected2', 'on' ]

    v.customize [ 
      'storageattach', :id, 
      '--storagectl', 'SATA Controller', 
      '--port', 1, 
      '--device', 0, 
      '--type', 'dvddrive', 
      '--medium', "#{ENV['BLOCK_PATH']}/base/cidata.vagrant.iso"
    ]
    v.customize [
      'storagectl', :id,
      '--name', 'SATA Controller',
      '--hostiocache', 'on'
    ]
  end

  config.vm.provider "aws" do |v, override|
    override.vm.box = ENV['BASEBOX_NAME']
    override.nfs.functional = false
    override.vm.synced_folder ENV['HOME'], '/vagrant', disabled: true
    override.vm.synced_folder '/data/cache/nodist', '/data/cache/nodist', type: "rsync", rsync__args: [ "-ia" ]
    override.vm.synced_folder ENV['AWS_SYNC'], ENV['AWS_SYNC'], type: "rsync", rsync__args: [ "-ia" ] if ENV['AWS_SYNC']

    override.vm.provision "shell", path: ci_script, args: [], privileged: true

    v.ami = "meh" if ENV['LIMBO_FAKE']

    v.region = ENV['AWS_DEFAULT_REGION']
    v.access_key_id = ENV['AWS_ACCESS_KEY_ID'] || %x{aws configure get aws_access_key_id}.chomp
    v.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY'] || %x{aws configure get aws_secret_access_key}.chomp
    v.session_token = ENV['AWS_SESSION_TOKEN'] if ENV['AWS_SESSION_TOKEN'] || %x{aws configure get aws_session_token}.chomp

    v.associate_public_ip = ENV['AWS_PUBLIC'] == "true" ? true : false
    v.ssh_host_attribute = ENV['AWS_PRIVATE'] == "true" ? :private_ip_address : :public_ip_address
    v.subnet_id = ENV['AWS_SUBNET'] if ENV['AWS_SUBNET']
    v.security_groups = [ ENV['AWS_SG'] ]

    v.keypair_name = ENV['AWS_KEYPAIR']
    v.instance_type = ENV['AWS_TYPE'] || 'c4.large'
    v.block_device_mapping = [
      { 'DeviceName' => '/dev/sda1', 'Ebs.VolumeSize' => 40 },
      { 'DeviceName' => '/dev/sdb', 'VirtualName' => 'ephemeral0', },
      { 'DeviceName' => '/dev/sdc', 'VirtualName' => 'ephemeral1', },
      { 'DeviceName' => '/dev/sdd', 'VirtualName' => 'ephemeral2', },
      { 'DeviceName' => '/dev/sde', 'VirtualName' => 'ephemeral3', }
    ]
    v.tags = {
      'Provisioner' => 'vagrant'
    }
  end
end
