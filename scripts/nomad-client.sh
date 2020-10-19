#!/bin/sh
	
		
	sudo yum -y install consul
	
	 consul agent -node=agent-two -bind=192.168.1.XXXXXXXX -enable-script-checks=true -data-dir=/tmp/consul -config-dir=/etc/consul.d
  --> Systemd
  
	sudo yum -y install nomad
			
				vi client1.hcl XXXXXXXX
				# Increase log verbosity
				log_level = "DEBUG"
				
				
				datacenter = "dc1"

				# Setup data dir
				data_dir = "/opt/nomad/client1" XXXXXXXX

				# Give the agent a unique name. Defaults to hostname
				name = "client1" XXXXXXXX

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
				
	sudo nomad agent server.hcl --> Systemd

  