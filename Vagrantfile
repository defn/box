Vagrant.configure("2") do |config|
  shome=File.expand_path("..", __FILE__)

  cibuild_script = %x{which block-cibuild 2>/dev/null}.strip
  cibuild_args = [ ENV['BASEBOX_HOME_URL'] ]

  unless ENV['http_proxy'].nil? || ENV['http_proxy'].empty?
    cibuild_args << ENV['http_proxy']
  end

  unless ENV['ssh_gateway'].nil? || ENV['ssh_gateway'].empty?
    cibuild_args << ENV['ssh_gateway']
  end

  config.ssh.username = "ubuntu"
  config.ssh.forward_agent = true
  config.ssh.insert_key = false

  config.vm.synced_folder ENV['BASEBOX_CACHE'], '/vagrant'

  ssh_keys = [
    "#{ENV['BASEBOX_CACHE']}/.ssh/ssh-vagrant",
    "#{ENV['BASEBOX_CACHE']}/.ssh/ssh-vagrant-insecure"
  ]
  
  config.vm.define "osx" do |region|
    region.vm.box = ENV['BASEBOX_NAME']
    region.vm.provision "shell", path: cibuild_script, args: cibuild_args, privileged: false

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
    region.vm.box = ENV['BASEBOX_NAME']
    region.ssh.private_key_path = ssh_keys
    region.vm.provision "shell", path: cibuild_script, args: cibuild_args, privileged: false
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
    end
  end

  (0..399).each do |nm_region|
    config.vm.define "#{nm_box}#{nm_region}" do |region|
      region.ssh.private_key_path = ssh_keys

      region.vm.provider "docker" do |v, override|
        if nm_region == 0
          region.vm.provision "shell", path: cibuild_script, args: cibuild_args, privileged: false
          v.image = ENV['BASEBOX_SOURCE'] || "#{ENV['BASEBOX_NAME']}:packer"
          v.create_args = []
          v.volumes = []
          v.cmd = [ "bash", "-c", "install -d -m 0755 -o root -g root /var/run/sshd; exec /usr/sbin/sshd -D -o VersionAddendum=#{nm_box}#{nm_region}" ]
        elsif (nm_region % 100) == 0
          region.vm.provision "shell", path: "script/dind", args: [], privileged: false
          v.image = ENV['BASEBOX_SOURCE'] || "#{ENV['BASEBOX_NAME']}:vagrant"
          v.create_args = ['--privileged']
          v.volumes = ['/var/lib/docker']
          v.cmd = [ "/usr/sbin/sshd", "-D", "-o", "VersionAddendum=#{nm_box}#{nm_region}" ]
        else
          v.image = ENV['BASEBOX_SOURCE'] || "#{ENV['BASEBOX_NAME']}:vagrant"
          v.create_args = []
          v.volumes = []
          v.cmd = [ "/usr/sbin/sshd", "-D", "-o", "VersionAddendum=#{nm_box}#{nm_region}" ]
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

      region.vm.box = "#{ENV['BASEBOX_NAME']}-#{nm_region}"
      region.ssh.private_key_path = ssh_keys
      region.vm.provision "shell", path: cibuild_script, args: cibuild_args, privileged: false

      region.vm.provider "aws" do |v|
        v.block_device_mapping = [
          { 'DeviceName' => '/dev/sda1', 'Ebs.VolumeSize' => 100 },
          { 'DeviceName' => '/dev/sdb', 'VirtualName' => 'ephemeral0', },
          { 'DeviceName' => '/dev/sdc', 'VirtualName' => 'ephemeral1', },
          { 'DeviceName' => '/dev/sdd', 'VirtualName' => 'ephemeral2', },
          { 'DeviceName' => '/dev/sde', 'VirtualName' => 'ephemeral3', }
        ]
        v.keypair_name = "vagrant-#{Digest::MD5.file(ssh_keys).hexdigest}"
        v.instance_type = 't2.small' # 'c3.large'
        v.region = nm_region
      end
    end
  end
end
