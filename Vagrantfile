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

  config.vm.provider "vmware_fusion" do |v, override|
    override.vm.box = ENV['BASEBOX_NAME']
    #override.vm.network "private_network", ip: ENV['BASEBOX_IP'], nic_type: "vmnet3"

    override.vm.synced_folder ENV['HOME'], '/vagrant', disabled: true
    override.vm.synced_folder '/data', '/data', type: "nfs"
    override.vm.synced_folder '/config', '/config', type: "nfs"

    override.vm.provision "shell", path: ci_script, args: [], privileged: true

    v.gui = false
    v.linked_clone = true
    v.verify_vmnet = true
    v.vmx["memsize"] = "1024"
    v.vmx["numvcpus"] = "1"

    v.vmx["ethernet0.vnet"] = "vmnet3"
    v.vmx["ethernet1.vnet"] = "vmnet3"

    v.vmx["ide1:0.present"]    = "TRUE"
    v.vmx["ide1:0.fileName"]   = "#{ENV['BLOCK_PATH']}/base/cidata.vagrant.iso"
    v.vmx["ide1:0.deviceType"] = "cdrom-image"
    v.vmx["ide1:0.startconnected"] = "TRUE"
  end

  config.vm.provider "parallels" do |v, override|
    override.vm.box = ENV['BASEBOX_NAME']
    #override.vm.network "private_network", ip: ENV['BASEBOX_IP']

    override.vm.synced_folder ENV['HOME'], '/vagrant', disabled: true
    override.vm.synced_folder '/data', '/data', type: "nfs"
    override.vm.synced_folder '/config', '/config', type: "nfs"


    override.vm.provision "shell", path: ci_script, args: [], privileged: true

    v.linked_clone = ENV['LIMBO_LINKED_CLONE'] ? true : false
    v.check_guest_tools = false
    
    v.memory = 1024
    v.cpus = 1

    v.customize [
      "set", :id,
      "--device-set", "cdrom0",
      "--image", "#{ENV['BLOCK_PATH']}/base/cidata.vagrant.iso",
      "--connect"
    ]
  end

  config.vm.provider "virtualbox" do |v, override|
    override.vm.box = ENV['BASEBOX_NAME']
    override.vm.network "private_network", ip: '172.28.128.10', nic_type: 'virtio'

    override.vm.synced_folder ENV['HOME'], '/vagrant', disabled: true
    override.vm.synced_folder '/data', '/data'
    override.vm.synced_folder '/config', '/config'

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
    override.vm.synced_folder ENV['HOME'], '/vagrant', disabled: true
    override.vm.synced_folder '/data/cache/packages', '/data/cache/packages'
    override.vm.synced_folder '/data/cache/wheels', '/data/cache/wheels'
    override.vm.synced_folder '/data/cache/nodist', '/data/cache/nodist'

    override.vm.provision "shell", path: ci_script, args: [], privileged: true

    v.ami = "meh" if ENV['LIMBO_FAKE']

    v.region = ENV['AWS_DEFAULT_REGION']
    v.access_key_id = ENV['AWS_ACCESS_KEY_ID'] || %x{aws configure get aws_access_key_id}.chomp
    v.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY'] || %x{aws configure get aws_secret_access_key}.chomp
    v.session_token = ENV['AWS_SESSION_TOKEN'] if ENV['AWS_SESSION_TOKEN'] || %x{aws configure get aws_session_token}.chomp

    v.associate_public_ip = ENV['AWS_PUBLIC'] ? true : false
    v.ssh_host_attribute = ENV['AWS_PRIVATE'] ? :private_ip_address : :public_ip_address
    v.subnet_id = ENV['AWS_SUBNET'] if ENV['AWS_SUBNET']
    v.security_groups = [ ENV['AWS_SG'] ]

    v.keypair_name = ENV['AWS_KEYPAIR']
    v.instance_type = 'm3.medium'
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
