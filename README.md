Opdracht 1
# Nomad consul

The aim of this project is to provide a development environment based on [consul](https://www.consul.io) and [nomad](https://www.nomadproject.io) to manage container based microservices.

The following steps should make that clear;

bring up the environment by using [vagrant](https://www.vagrantup.com) which will create centos 7 virtualbox machine or lxc container.

The proved working vagrant providers used on an [ArchLinux](https://www.archlinux.org/) system are
* [vagrant-lxc](https://github.com/fgrehm/vagrant-lxc)
* [vagrant-libvirt](https://github.com/vagrant-libvirt/)
* [virtualbox](https://www.virtualbox.org/)

```bash
    $ vagrant up --provider lxc
    OR
    $ vagrant up --provider libvirt
    OR
    $ vagrant up --provider virtualbox
```

Once it is finished, you should be able to connect to the vagrant environment through SSH and interact with Nomad:

```bash
    $ vagrant ssh
    [vagrant@nomad ~]$
```


# Opdracht 1

Om de cluster op te zetten hebben we in de vagrantfile een script geschreven dat de clients aanmaakt door middel van iteraties te gebruiken, zo kunnen we elke client opeenvolgende namen en ip-adressen toekennen.
We hebben scripts voorzien om systeemupdates te zoeken en uit te voeren, docker te installeren en daarna de effectieve configuratie en installaties op de clients en server zelf.

In het docker script halen we de officiiële hashicorp repository binnen om zo snel nomad en consul te kunnen installeren.
script docker:
```bash
	#!/bin/sh

	sudo yum install -y yum-utils
	sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	sudo yum install -y docker-ce docker-ce-cli containerd.io

	sudo systemctl enable docker
	sudo systemctl start docker

	sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
```


clients(in vagrantfile):
```bash
	(1..2).each do |i|
	config.vm.define "Nomad-Client-#{i}" do |client| 
	client.vm.hostname = "Nomad-Client-#{i}"
	client.vm.network "private_network", ip:"192.168.1.#{i+1}", virtualbox__intnet:"mynetwork"
	client.vm.provision "shell", path: "scripts/nomad-client#{i}.sh"
	end
  end
```
server(in vagrantfile):
```bash
	config.vm.define "Nomad-Server" do |server| 
	server.vm.hostname = "Nomad-Server"
	server.vm.network "private_network", ip:"192.168.1.1", virtualbox__intnet:"mynetwork"
	server.vm.provision "shell", path: "scripts/nomad-Server.sh"
  end
```

Het script dat de clients gebruiken is hetzelfde voor beide clients buiten de ip-adressen die gebind moeten worden.
In het script zorgen we ervoor dat de clients de juiste waardes toegekend krijgen in hun config files, hiervoor kiezen we om met "sed" te werken omdat we zo makkelijk de lijnen die al bestaan in het bestand kunnen aanpassen naar wat de client nodig heeft.
Na de config files aan te passen installeren we consul en nomad. Nomad heeft nog wat werk nodig in de config files dus hebben we de file helemaal in het script gezet exact zoals we de config file willen.
Na de config file van nomad aan te passen kunnen we nomad dan ook opstarten.
script clients:
```bash
	#!/bin/sh
	
		
	sudo yum -y install consul

  
	sudo sed -i 's+#server = true+server = false+' /etc/consul.d/consul.hcl 
	sudo  sed -i '$ a bind_addr = "192.168.1.2"' /etc/consul.d/consul.hcl
	sudo  sed -i '$ a retry_join = ["192.168.1.1"]' /etc/consul.d/consul.hcl


	sudo systemctl  enable consul
	sudo systemctl  start consul
  
	sudo yum -y install nomad
			
	cat << EOF > /etc/nomad.d/nomad.hcl
				# Increase log verbosity
				log_level = "DEBUG"
				
				bind_addr = "192.168.1.2"
				datacenter = "dc1"

				# Setup data dir
				data_dir = "/opt/nomad/client1" 

				

				# Enable the client
				client {
					enabled = true
					servers = ["192.168.1.1"]
				}

				# Disable the dangling container cleanup to avoid interaction with other clients
				plugin "docker" {
				  config {
					gc {
					  dangling_containers {
						enabled = false
					  }
					}
				  }
				}
EOF

mkdir /opt/nomad/client1

systemctl  enable nomad
systemctl  start nomad
```


Voor de server hebben we ook weer eerst de config files aangepast aan de noden van de server en daarna kunnen we consul opstarten, nomad installeren en configureren en nomad uiteindelijk opstarten.
script server:
```bash
	#!/bin/sh

	sudo yum -y install consul

	sudo sed -i 's+#server = true+server = true+' /etc/consul.d/consul.hcl 
	sudo  sed -i '$ a bind_addr = "192.168.1.1"' /etc/consul.d/consul.hcl
	sudo sed -i 's+#bootstrap_expect=3+bootstrap_expect=1+' /etc/consul.d/consul.hcl 
	sudo sed -i '$ a export NOMAD_ADDR=http://192.168.1.1:4646' .bashrc



	sudo systemctl enable consul
	sudo systemctl  start consul
	
	
	sudo yum -y install nomad

	
	cat << EOF > /etc/nomad.d/nomad.hcl
		# Increase log verbosity
			log_level = "DEBUG"

			data_dir = "/opt/nomad/data"
			bind_addr = "192.168.1.1"
				
		# Enable the server
			server {
				enabled = true

				# Self-elect, should be 3 or 5 for production
				bootstrap_expect = 1
		}
	EOF
	
	systemctl  enable nomad
	systemctl  start nomad
```

De Consul gui kan geopend worden in de browser te surfen naar localhost:8500 na het uitvoeren van volgend commando om de juiste port te forwarden:
```bash
vagrant ssh -- -L 8500:192.168.1.1:8500
```
Analoog voor de Nomad gui:
```bash
vagrant ssh -- -L 8500:192.168.1.1:4646
```

Bronvermelding
https://www.consul.io/docs
https://www.nomadproject.io/docs
https://www.vagrantup.com/docs/vagrantfile
https://www.vagrantup.com/docs/vagrantfile/tips

# Opdracht 2

Voor deze opdracht hebben we gekozen om met ansible te werken, onze vagrantfile is dus aangepast om ansible te gebruiken.
Als ansible provisioner kiezen we voor "ansible_local" om op onze windows 10 machines te kunnen werken.
De servers en clients gebruiken dezelfde playbook maar in die playbook wordt er onderscheid gemaakt tussen server en client.

```bash
	config.vm.define :server do |server| 
	server.vm.hostname = "Nomad-Server"
	server.vm.network "private_network", ip:"192.168.1.1", virtualbox__intnet:"mynetwork"
	
	
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
```

Onze playbook ziet er als volgt uit:
Om sommige dingen uit te voeren waar je normaal "sudo" voor moet gebruiken maken we hier gebruik van de lijn "become: yes". Wanneer dit in het playbook wordt gedefinieerd moet dit niet meer telken in elke role apart gedaan worden maar kan ansible telkens met sudo-rechten taken uitvoeren.
```bash
	---
	- name: Plays server vm
	  hosts: servers
      become: yes
      roles:
        - software/consul
        - software/nomad

    - name: Plays client vm
      hosts: clients
      become: yes
      roles:
        - software/docker
        - software/consul
        - software/nomad

```

Bij de dockerrol halen we eerst de repo binnen die we nodig hebben om docker te installeren op de vm, daarna wordt deze geïnstalleerd, uitgevoerd en enabled.
We voegen de vagrantgebruiker toe aan de docker groep zodat er containers gemanaged kunnen worden via ansible omdat deze gebruiker gebruikt wordt om de taken uit te voeren die ansible specifieerd.

```bash
	---
    - name: Add Docker repo
	  yum_repository:
	  name: docker-ce
      description: Docker repo
      baseurl: https://download.docker.com/linux/centos/$releasever/$basearch/stable
      gpgkey: https://download.docker.com/linux/centos/gpg

    - name: Install Docker
      package:
        name: docker-ce
		state: latest

	- name: Start Docker
	service:
		name: docker
		state: started

	- name: Add Vagrant user to docker group for managing docker without sudo
	  user:
		name: vagrant
		groups: docker
		append: yes
```

De installatie en configuratie van nomad en consul gebeurt analoog aan de docker role. Voor nomad maken we nog een directory aan met de juiste rechten en voor beide gebruiken we een template voor de configuratie:

```bash
	- name: Create Nomad directory
	  file:
		path: /opt/nomad/
		state: directory
		mode: '0755'
		
	- name: Template for Nomad configuration
	  template:
		src: nomad.hcl.j2
		dest: /etc/nomad.d/nomad.hcl
```

Als laatste laten we de config files zien die gebruikt worden voor nomad en consul.
nomad:
```bash
#!/bin/bash
# {{ ansible_managed }}
# {{ ansible_default_ipv4.address }}
# {{ ansible_eth1.ipv4.address }}

datacenter = "dc1",
client_addr = "0.0.0.0",
bind_addr = "{{ ansible_eth1.ipv4.address }}",
rejoin_after_leave = true,
ui = true,

{% if consul_master == "yes" %}
bootstrap_expect = {{ groups['servers'] | length }},
{% endif %}

{% if consul_join == "yes" %}
start_join = [ "192.168.1.1" ],
{% endif %}

data_dir = "/opt/consul/",
{% if consul_server == "yes" %}
server = true
{% else %}
server = false
{% endif %}
```

consul:
```bash
#!/bin/bash
# {{ ansible_managed }}
# {{ ansible_default_ipv4.address }}
# {{ ansible_eth1.ipv4.address }}

datacenter = "dc1",
data_dir = "/opt/nomad/{{ inventory_hostname }}",
bind_addr = "{{ ansible_eth1.ipv4.address }}",

{% if nomad_server == "yes" %}
server {
    enabled = true,
{% if nomad_master == "yes" %}
    bootstrap_expect = {{ groups['servers'] | length }},
{% endif %}

}
{% else %}
client {
    enabled = true,
    servers = [ "192.168.1.1" ],
    network_interface = "eth1",
}
{% endif %}

```