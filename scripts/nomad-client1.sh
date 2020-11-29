#!/bin/sh
	
  
sudo sed -i 's+#server = true+server = false+' /etc/consul.d/consul.hcl 
sudo  sed -i '$ a bind_addr = "192.168.1.2"' /etc/consul.d/consul.hcl
sudo  sed -i '$ a retry_join = ["192.168.1.1"]' /etc/consul.d/consul.hcl


sudo systemctl  enable consul
sudo systemctl  start consul

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

  