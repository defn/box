shome=File.expand_path("..", __FILE__)

ci_script = "#{shome}/script/cloud-init-bootstrap"

aws_region = ENV['AWS_DEFAULT_REGION']
aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
aws_secret_access_key= ENV['AWS_SECRET_ACCESS_KEY']

if ENV['VAGRANT_DEFAULT_PROVIDER'] == "aws"
  threads = []
  threads << Thread.new do aws_region = ENV['AWS_DEFAULT_REGION'] || %x{aws configure get region}.chomp; end
  threads << Thread.new do aws_access_key_id = ENV['AWS_ACCESS_KEY_ID'] || %x{aws configure get aws_access_key_id}.chomp; end
  threads << Thread.new do aws_secret_access_key= ENV['AWS_SECRET_ACCESS_KEY'] || %x{aws configure get aws_secret_access_key}.chomp; end

  threads.map(&:join)
end

ssh_keys = [
  "#{shome}/.ssh/ssh-container"
]

Vagrant.configure("2") do |config|
  config.ssh.shell = "bash"
  config.ssh.username = "ubuntu"
  config.ssh.forward_agent = true
  config.ssh.insert_key = false
  config.ssh.private_key_path = ssh_keys

  config.vm.base_mac = "00163EFFFF#{sprintf("%02x",ENV['BASEBOX_IP'].split(".")[-1].to_i)}"

  config.vm.provider "vmware_fusion" do |v, override|
    override.vm.box = ENV['BASEBOX_NAME']
    override.vm.network "private_network", ip: ENV['BASEBOX_IP'], nic_type: "vmnet3"

    override.vm.synced_folder ENV['CACHE_DIR'], '/vagrant', type: "nfs"

    override.vm.provision "shell", path: ci_script, args: [], privileged: true

    v.gui = false
    v.linked_clone = true
    v.verify_vmnet = true
    v.vmx["memsize"] = "1024"
    v.vmx["numvcpus"] = "1"

    v.vmx["ethernet0.vnet"] = "vmnet3"
    v.vmx["ethernet1.vnet"] = "vmnet3"

    v.vmx["ide1:0.present"]    = "TRUE"
    v.vmx["ide1:0.fileName"]   = "#{shome}/cidata.iso"
    v.vmx["ide1:0.deviceType"] = "cdrom-image"
    v.vmx["ide1:0.startconnected"] = "TRUE"
  end

  config.vm.provider "parallels" do |v, override|
    override.vm.box = ENV['BASEBOX_NAME']
    override.vm.network "private_network", ip: ENV['BASEBOX_IP']

    override.vm.synced_folder ENV['CACHE_DIR'], '/vagrant', type: "nfs"

    override.vm.provision "shell", path: ci_script, args: [], privileged: true

    v.linked_clone = ENV['LIMBO_LINKED_CLONE'] ? true : false
    v.check_guest_tools = false
    
    v.memory = 1024
    v.cpus = 1

    v.customize [
      "set", :id,
      "--device-set", "cdrom0",
      "--image", "#{shome}/cidata.iso",
      "--connect"
    ]
  end

  config.vm.provider "virtualbox" do |v, override|
    override.vm.box = ENV['BASEBOX_NAME']
    override.vm.network "public_network", bridge: "#{ENV['LIMBO_BRIDGE'] || "en1: Wi-Fi (AirPort)"}", mac: "00163EFF#{sprintf("%02x",ENV['BASEBOX_IP'].split(".")[-1].to_i)}FF", nic_type: "virtio"
    override.vm.network "private_network", ip: ENV['BASEBOX_IP'], mac: "00163E#{sprintf("%02x",ENV['BASEBOX_IP'].split(".")[-1].to_i)}FFFF",  auto_config: false, nic_type: "virtio"

    override.vm.synced_folder ENV['CACHE_DIR'], '/vagrant'

    override.vm.provision "shell", path: ci_script, args: [], privileged: true

    v.linked_clone = true
    v.memory = 1024
    v.cpus = 1

    v.customize [ 'modifyvm', :id, '--nictype1', 'virtio' ]
    v.customize [ 'modifyvm', :id, '--paravirtprovider', 'kvm' ]

    v.customize [ 
      'storageattach', :id, 
      '--storagectl', 'SATA Controller', 
      '--port', 1, 
      '--device', 0, 
      '--type', 'dvddrive', 
      '--medium', "#{shome}/cidata.iso"
    ]
    v.customize [
      'storagectl', :id,
      '--name', 'SATA Controller',
      '--hostiocache', 'on'
    ]
  end

  config.vm.provider "aws" do |v, override|
    override.vm.box = ENV['BASEBOX_NAME']
    override.vm.synced_folder ENV['CACHE_DIR'], '/vagrant', disabled: true

    override.vm.provision "shell", path: ci_script, args: [], privileged: true

    v.ami = "meh" if ENV['LIMBO_FAKE']

    v.region = aws_region
    v.access_key_id = aws_access_key_id
    v.secret_access_key= aws_secret_access_key

    v.keypair_name = "vagrant-#{Digest::MD5.file("#{shome}/.ssh/ssh-container.pub").hexdigest}"
    v.instance_type = 't2.medium'
    v.block_device_mapping = [
      { 'DeviceName' => '/dev/sda1', 'Ebs.VolumeSize' => 100 },
      { 'DeviceName' => '/dev/sdb', 'VirtualName' => 'ephemeral0', },
      { 'DeviceName' => '/dev/sdc', 'VirtualName' => 'ephemeral1', },
      { 'DeviceName' => '/dev/sdd', 'VirtualName' => 'ephemeral2', },
      { 'DeviceName' => '/dev/sde', 'VirtualName' => 'ephemeral3', }
    ]
    v.tags = {
      'Provisioner' => 'vagrant'
    }
  end

  config.vm.provider "docker" do |v, override|
    override.vm.synced_folder ENV['CACHE_DIR'], '/vagrant'

    v.image = ENV['BASEBOX_SOURCE'] || "#{ENV['BASEBOX_NAME']}:vagrant"
    v.cmd = [ "/usr/sbin/sshd", "-D" ]
    v.volumes = [ "/var/run/sshd" ]
    v.create_args = [ ]
    v.has_ssh = true

    module VagrantPlugins
      module DockerProvider
        class Provider < Vagrant.plugin("2", :provider)
          def host_vm?
            false
          end
        end
        module Action
          class Create
            def forwarded_ports(include_ssh=false)
              return []
            end
          end
        end
      end
    end # end docker monkey patching
  end
end
