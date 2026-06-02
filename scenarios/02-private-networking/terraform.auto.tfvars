location    = "eastus2"
environment = "dev"
workload    = "foundry"
scenario_id = "s02"
instance    = "001"

vnet_address_space             = "192.168.0.0/16"
agent_subnet_prefix            = "192.168.0.0/24"
private_endpoint_subnet_prefix = "192.168.1.0/24"

tags = {
  Owner = "chris.house.00@gmail.com"
}
