aws_region = ENV['AWS_DEFAULT_REGION'] || %x{aws configure get region}.chomp
aws_access_key_id = ENV['AWS_ACCESS_KEY_ID'] || %x{aws configure get aws_access_key_id}.chomp
aws_secret_access_key= ENV['AWS_SECRET_ACCESS_KEY'] || %x{aws configure get aws_secret_access_key}.chomp

Vagrant.configure("2") do |config|
  shome=File.expand_path("..", __FILE__)

  docker_script = "#{shome}/script/docker-bootstrap"
  docker_args = [ ENV['BASEBOX_DOCKER_NETWORK_PREFIX'] ]

  block_script = %x{which block-cibuild 2>/dev/null}.strip
  block_args = [ ENV['BASEBOX_HOME_URL'] ]
  %w(http_proxy ssh_gateway ssh_gateway_user).each {|ele|
    unless ENV[ele].nil? || ENV[ele].empty?
      block_args << ENV[ele]
    else
      break
    end
  }

  facts_script = "#{shome}/script/facts-finish"
  facts_args = [ ]

  if ENV['ssh_gateway_user'].nil? || ENV['ssh_gateway_user'].empty?
    block_args << ENV['USER']
  end

  config.ssh.username = "ubuntu"
  config.ssh.forward_agent = true
  config.ssh.insert_key = false
  config.ssh.private_key_path = [
    "#{shome}/.ssh/ssh-vagrant",
    "#{shome}/.ssh/ssh-vagrant-insecure"
  ]

  config.vm.define ENV['BASEBOX_NAME'] do |basebox|
    case ENV['VAGRANT_DEFAULT_PROVIDER']
    when "vmware_fusion"
      basebox.vm.box = ENV['BASEBOX_NAME']

      basebox.vm.network "private_network", ip: ENV['BASEBOX_IP'], nic_type: "vmnet3"

      basebox.vm.provider "vmware_fusion" do |v, override|
        override.vm.synced_folder ENV['CACHE_DIR'], '/vagrant', type: "nfs"
        override.vm.synced_folder "#{ENV['CACHE_DIR']}/tmp/packer", '/vagrant/tmp/packer', type: "nfs"

        override.vm.provision "shell",
          inline: "rm -f /var/lib/cloud/instance; cloud-init init || true",
          privileged: true
        override.vm.provision "shell", path: docker_script, args: docker_args, privileged: false
        override.vm.provision "shell", path: block_script,  args: block_args, privileged: false
        override.vm.provision "shell", path: facts_script,  args: facts_args, privileged: false

        v.gui = false
        v.linked_clone = true
        v.verify_vmnet = true
        v.vmx["memsize"] = "2048"
        v.vmx["numvcpus"] = "2"

        v.vmx["ethernet0.vnet"] = "vmnet3"
        v.vmx["ethernet1.vnet"] = "vmnet3"

				v.vmx["ide1:0.present"]    = "TRUE"
				v.vmx["ide1:0.fileName"]   = "#{ENV['LIMBO_HOME']}/cidata.iso"
				v.vmx["ide1:0.deviceType"] = "cdrom-image"
				v.vmx["ide1:0.startconnected"] = "TRUE"
      end
    when "virtualbox"
      basebox.vm.box = ENV['BASEBOX_NAME']

      basebox.vm.network "private_network", ip: ENV['BASEBOX_IP']

      basebox.vm.provider "virtualbox" do |v, override|
        override.vm.synced_folder ENV['CACHE_DIR'], '/vagrant'
        override.vm.synced_folder "#{ENV['CACHE_DIR']}/tmp/packer", '/vagrant/tmp/packer'

        override.vm.provision "shell",
          inline: "rm -f /var/lib/cloud/instance; cloud-init init || true",
          privileged: true
        override.vm.provision "shell", path: docker_script,  args: docker_args, privileged: false
        override.vm.provision "shell", path: block_script,   args: block_args, privileged: false
        override.vm.provision "shell", path: facts_script,   args: facts_args, privileged: false

        v.linked_clone = true
        v.memory = 2048
        v.cpus = 2

        v.customize [ 'modifyvm', :id, '--nictype1', 'virtio' ]
        v.customize [ 'modifyvm', :id, '--nictype2', 'virtio' ]

        v.customize [ 
          'storageattach', :id, 
          '--storagectl', 'SATA Controller', 
          '--port', 1, 
          '--device', 0, 
          '--type', 'dvddrive', 
          '--medium', "#{ENV['LIMBO_HOME']}/cidata.iso"
        ]
				v.customize [
					'storagectl', :id,
					'--name', 'SATA Controller',
					'--hostiocache', 'on'
				]
      end
    when "aws"
      basebox.vm.box = ENV['BASEBOX_NAME']

      basebox.vm.provider "aws" do |v, override|
        override.vm.synced_folder ENV['CACHE_DIR'], '/vagrant', disabled: true
          
        override.vm.provision "shell",
          inline: "rm -f /var/lib/cloud/instance; cloud-init init || true",
          privileged: true
        override.vm.provision "shell", path: block_script, args: [ ENV['BASEBOX_HOME_URL'] ], privileged: false

        v.ami = "meh" if ENV['LIMBO_FAKE']

        v.region = aws_region
        v.access_key_id = aws_access_key_id
        v.secret_access_key= aws_secret_access_key

        v.keypair_name = "vagrant-#{Digest::MD5.file("#{ssh_keys[0]}.pub").hexdigest}"
        v.instance_type = 'm3.medium'
        v.block_device_mapping = [
          { 'DeviceName' => '/dev/sda1', 'Ebs.VolumeSize' => 100 },
          { 'DeviceName' => '/dev/sdf',  'Ebs.VolumeSize' => 100 },
          { 'DeviceName' => '/dev/sdb', 'VirtualName' => 'ephemeral0', },
          { 'DeviceName' => '/dev/sdc', 'VirtualName' => 'ephemeral1', },
          { 'DeviceName' => '/dev/sdd', 'VirtualName' => 'ephemeral2', },
          { 'DeviceName' => '/dev/sde', 'VirtualName' => 'ephemeral3', }
        ]
        v.tags = {
          'Provisioner' => 'vagrant'
        }
      end
    when "docker"
      basebox.vm.provider "docker" do |v, override|
        override.vm.synced_folder ENV['CACHE_DIR'], '/vagrant'
        override.vm.synced_folder "#{ENV['CACHE_DIR']}/tmp/packer", '/vagrant/tmp/packer'

        override.vm.provision "shell", path: block_script, args: block_args, privileged: false

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
  end
end
