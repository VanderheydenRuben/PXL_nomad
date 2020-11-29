# -*- mode: ruby -*-
# vi: set ft=ruby :
VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "centos/7"

#	(1..2).each do |i|
#	config.vm.define "Nomad-Client-#{i}" do |client| 
#	client.vm.hostname = "Nomad-Client-#{i}"
#	client.vm.network "private_network", ip:"192.168.1.#{i+1}", virtualbox__intnet:"mynetwork"
#	#client.vm.provision "shell", path: "scripts/nomad-client#{i}.sh"
#	end
#  end
	(1..2).each do |i|
	config.vm.define "Nomad-Client-#{i}"  do |client| 
	client.vm.hostname = "Nomad-Client-#{i}"
	client.vm.network "private_network", ip:"192.168.1.#{i+1}", virtualbox__intnet:"mynetwork"
	
	client.vm.provision "ansible_local" do |ansible|
      ansible.config_file = "ansible/ansible.cfg"
      ansible.playbook = "ansible/plays/client.yml"
      ansible.groups = {
        "clients" => ["Nomad-Client-#{i}"],
#        "clients:vars" => {"crond__content" => "client_value"}
      }
      ansible.host_vars = {
#        "client" => {"crond__content" => "client_value"}
      }
#      ansible.verbose = '-vvv'
    end
	client.vm.provision "shell", path: "scripts/nomad-client#{i}.sh"
  end
end

  config.vm.define :server do |server| 
	server.vm.hostname = "Nomad-Server"
	server.vm.network "private_network", ip:"192.168.1.1", virtualbox__intnet:"mynetwork"
	
	
	server.vm.provision "ansible_local" do |ansible|
      ansible.config_file = "ansible/ansible.cfg"
      ansible.playbook = "ansible/plays/server.yml"
      ansible.groups = {
        "servers" => ["server"],
#        "servers:vars" => {"crond__content" => "servers_value"}
      }
      ansible.host_vars = {
#        "server" => {"crond__content" => "server_value"}
      }
#      ansible.verbose = '-vvv'
    end
	server.vm.provision "shell", path: "scripts/nomad-Server.sh"
  end


  config.vm.provider :virtualbox do |virtualbox, override|
    virtualbox.customize ["modifyvm", :id, "--memory", 2048]
  end

  config.vm.provider :lxc do |lxc, override|
    override.vm.box = "visibilityspots/centos-7.x-minimal"
  end

	#config.vm.provision "shell", path: "scripts/update.sh" 	
	#config.vm.provision "shell", path: "scripts/docker.sh" 	

end
