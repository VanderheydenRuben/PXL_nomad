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
