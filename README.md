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

Bronvermelding
https://www.consul.io/docs
https://www.nomadproject.io/docs
https://www.vagrantup.com/docs/vagrantfile
https://www.vagrantup.com/docs/vagrantfile/tips
