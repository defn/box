shome=File.expand_path("..", __FILE__)

ci_script = "#{shome}/script/cloud-init-bootstrap"

Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox" do |v, override|
    override.vm.box = ENV['BASEBOX_NAME']
    override.vm.box = ENV['BASEBOX_NAME_OVERRIDE'] if ENV['BASEBOX_NAME_OVERRIDE']
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
    override.vm.box = ENV['BASEBOX_NAME_OVERRIDE'] ? ENV['BASEBOX_NAME_OVERRIDE'] : ENV['BASEBOX_NAME']
    override.vm.synced_folder '/data/cache/nodist', '/data/cache/nodist', type: "rsync", rsync__args: [ "-ia" ]
    override.vm.synced_folder ENV['AWS_SYNC'], ENV['AWS_SYNC'], type: "rsync", rsync__args: [ "-ia" ] if ENV['AWS_SYNC']
    override.vm.provision "shell", path: ci_script, args: [], privileged: true
  end
end
