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

	config.vm.define :server do |server| 
	server.vm.hostname = "Nomad-Server"
	server.vm.network "private_network", ip:"192.168.1.1", virtualbox__intnet:"mynetwork"
	server.vm.network "forwarded_port", guest: 4646, host: 4646
	#server.vm.network "forwarded_port", guest: 8500, host: 8500
	
	server.vm.provision "ansible_local" do |ansible|
      ansible.config_file = "ansible/ansible.cfg"
      ansible.playbook = "ansible/plays/playbook.yml"
      ansible.groups = {
        "servers" => ["server"],
		"servers:vars" => {"consul_master" => "yes", "consul_join" => "no", "consul_server"=> "yes", "nomad_master" => "yes", "nomad_server" => "yes"}
      }
    end
  end
  
	(1..2).each do |i|
	config.vm.define "Nomad-Client-#{i}"  do |client| 
	client.vm.hostname = "Nomad-Client-#{i}"
	client.vm.network "private_network", ip:"192.168.1.#{i+1}", virtualbox__intnet:"mynetwork"
	
	client.vm.provision "ansible_local" do |ansible|
      ansible.config_file = "ansible/ansible.cfg"
      ansible.playbook = "ansible/plays/playbook.yml"
      ansible.groups = {
        "clients" => ["Nomad-Client-#{i}"],
        "clients:vars" => {"consul_master" => "no", "consul_join" => "yes", "consul_server"=> "no", "nomad_master" => "no", "nomad_server" => "no"}
      }
#      ansible.verbose = '-vvv'
	end
  end
end


  
  config.vm.provider :virtualbox do |virtualbox, override|
    virtualbox.customize ["modifyvm", :id, "--memory", 2048]
  end

  config.vm.provider :lxc do |lxc, override|
    override.vm.box = "visibilityspots/centos-7.x-minimal"
  end

end
