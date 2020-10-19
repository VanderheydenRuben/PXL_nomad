#!/bin/sh

	sudo yum -y install consul
	
	consul agent -server -bootstrap-expect=1 -node=agent-one -bind=192.168.1.1 -data-dir=/tmp/consul -config-dir=/etc/consul.d
  --> Systemd
  
	consul join 192.168.1.2  # Na opzetten clients
	consul join 192.168.1.3
	
	sudo yum -y install nomad

	
	nano server.hcl
			# Increase log verbosity
					log_level = "DEBUG"


					# Enable the server
					server {
						enabled = true

						# Self-elect, should be 3 or 5 for production
						bootstrap_expect = 1
					}
			
	mkdir /opt/nomad/client1
	sudo nomad agent -config client1.hcl --> Systemd
	


#DEFAULT NOMAD   /etc/nomad.d/nomad.hcl
# Full configuration options can be found at https://www.nomadproject.io/docs/configuration

data_dir = "/opt/nomad/data"
bind_addr = "0.0.0.0"

server {
  enabled = true
  bootstrap_expect = 1
}

client {
  enabled = true
  servers = ["127.0.0.1:4646"]
}
~    