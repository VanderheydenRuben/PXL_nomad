#!/bin/sh
	
		
sudo yum -y install consul
	
	# consul agent -node=agent-two -bind=192.168.1.2 -enable-script-checks=true -data-dir=/tmp/consul -config-dir=/etc/consul.d

  
sudo sed -i 's+#server = true+server = false+' /etc/consul.d/consul.hcl 
sudo sed -i 's+client_addr = "0.0.0.0"+bind_addr = "192.168.1.3"+' /etc/consul.d/consul.hcl 

sudo chmod -R 777 /opt/consul/ 

sudo systemctl  enable consul
sudo systemctl  start consul
  
sudo yum -y install nomad
			
cat << EOF > /etc/nomad.d/nomad.hcl
				# Increase log verbosity
				log_level = "DEBUG"
				
				
				datacenter = "dc1"

				# Setup data dir
				data_dir = "/opt/nomad/client2" 

				# Give the agent a unique name. Defaults to hostname
				name = "client2" 

				# Enable the client
				client {
					enabled = true
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

mkdir /opt/nomad/client2
	# sudo nomad agent server.hcl --> Systemd
systemctl  enable nomad
systemctl  start nomad

  