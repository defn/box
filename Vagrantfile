require 'socket'

shome=File.expand_path("..", __FILE__)

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

  cibuild_args = %w(git@github.com:defn/home)
  unless ENV['http_proxy'].nil? || ENV['http_proxy'].empty?
    cibuild_args << ENV['http_proxy']
  end

  config.ssh.username = "ubuntu"
  config.ssh.forward_agent = true

  config.vm.synced_folder ENV['BASEBOX_CACHE'], '/vagrant'

  ssh_key = "#{ENV['HOME']}/.ssh/ssh-vagrant"
  
  config.vm.define "osx" do |region|
    region.vm.box = "ubuntu"
    region.ssh.insert_key = false
    region.vm.provision "shell", path: "script/cibuild", args: cibuild_args, privileged: false

    region.vm.provider "vmware_fusion" do |v|
      v.gui = false
      v.linked_clone = true
      v.verify_vmnet = true
      v.vmx["memsize"] = "4096"
      v.vmx["numvcpus"] = "2"

      v.vmx["ethernet0.present"] = "TRUE"
      v.vmx["ethernet0.connectionType"] = "nat"
    end
  end

  nm_box=ENV['BOX_NAME']

  config.vm.define nm_box do |region|
    region.vm.box = "ubuntu"
    region.ssh.private_key_path = ssh_key
    region.vm.provision "shell", path: "script/cibuild", args: cibuild_args, privileged: false
    region.vm.network "private_network", ip: "172.28.128.3" # VBoxManage hostonlyif ipconfig vboxnet0 --ip 172.28.128.1 --netmask 255.255.255.0

    region.vm.provider "virtualbox" do |v|
      v.linked_clone = true
      v.memory = 4096
      v.cpus = 2

      if File.exists?("#{shome}/cidata.iso")
        v.customize [ 
          'storageattach', :id, 
          '--storagectl', 'SATA Controller', 
          '--port', 1, 
          '--device', 0, 
          '--type', 'dvddrive', 
          '--medium', "#{shome}/cidata.iso"
        ]
      end

      file_to_disk="#{shome}/.#{nm_box}.vdi"
      v.customize ['createhd', '--filename', file_to_disk, '--size', 500 * 1024] unless File.exists? file_to_disk
      v.customize [
          'storageattach', :id, 
          '--storagectl', 'SATA Controller', 
          '--port', 2, 
          '--device', 0, 
          '--type', 'hdd', 
          '--medium', file_to_disk
      ]

    end
  end

  (0..100).each do |nm_region|
    config.vm.define "#{nm_box}#{nm_region}" do |region|
      region.ssh.insert_key = false

      if nm_region == 0
        region.vm.provision "shell", path: "script/cibuild", args: cibuild_args, privileged: false
      elsif nm_region == 100
        region.vm.provision "shell", path: "script/dind", privileged: false
      end

      region.vm.provider "docker" do |v, override|
        if nm_region == 0
          v.image = "ubuntu:packer"
          v.cmd = [ "bash", "-c", "install -d -m 0755 -o root -g root /var/run/sshd; exec /usr/sbin/sshd -D" ]
        elsif nm_region == 100
          v.image = "ubuntu:vagrant"
          v.create_args = ['--privileged']
          v.volumes = ['/var/lib/docker']
          v.cmd = [ "/usr/sbin/sshd", "-D" ]
        else
          v.image = "ubuntu:vagrant"
          v.cmd = [ "/usr/sbin/sshd", "-D" ]
        end
        
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
        end
      end
    end
  end

  (ENV['AWS_REGIONS']||"").split(" ").each do |nm_region|
    config.vm.define nm_region do |region|
      region.vm.synced_folder ENV['BASEBOX_CACHE'], '/vagrant', disabled: true
      region.vm.synced_folder "#{shome}/remote/#{nm_region}/.", '/vagrant/', type: "rsync" if File.exists?("#{shome}/remote/#{nm_region}/.")

      region.vm.box = "ubuntu-#{nm_region}"
      region.ssh.private_key_path = ssh_key
      region.vm.provision "shell", path: "script/cibuild", args: cibuild_args, privileged: false

      region.vm.provider "aws" do |v|
        v.block_device_mapping = [
          { 'DeviceName' => '/dev/sda1', 'Ebs.VolumeSize' => 50 },
          { 'DeviceName' => '/dev/sdb', 'VirtualName' => 'ephemeral0', },
          { 'DeviceName' => '/dev/sdc', 'VirtualName' => 'ephemeral1', },
          { 'DeviceName' => '/dev/sdd', 'VirtualName' => 'ephemeral2', },
          { 'DeviceName' => '/dev/sde', 'VirtualName' => 'ephemeral3', }
        ]
        v.keypair_name = "vagrant-#{Digest::MD5.file(ssh_key).hexdigest}"
        v.instance_type = 't2.small' # 'c3.large'
        v.region = nm_region
      end
    end
  end
end
