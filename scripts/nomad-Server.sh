#!/bin/sh

sudo yum -y install consul
	
	#consul agent -server -bootstrap-expect=1 -node=agent-one -bind=192.168.1.1  -config-dir=/etc/consul.d
	# --> Systemd  
sudo sed -i 's+#server = true+server = true+' /etc/consul.d/consul.hcl 
sudo  sed -i '$ a bind_addr = "192.168.1.1"' /etc/consul.d/consul.hcl
sudo sed -i 's+#bootstrap_expect=3+bootstrap_expect=1+' /etc/consul.d/consul.hcl 
sudo sed -i '$ a export NOMAD_ADDR=http://192.168.1.1:4646' .bashrc

#retry_join = ["[::1]:8301"]  

sudo chmod -R 755/opt/consul/ 

sudo systemctl enable consul
sudo systemctl  start consul
	
#consul join 192.168.1.2  # Na opzetten clients
#consul join 192.168.1.3
	
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
	
	
	
	# sudo nomad agent -config client1.hcl --> Systemd
systemctl  enable nomad
systemctl  start nomad
