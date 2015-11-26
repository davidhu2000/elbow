require 'aws-sdk'
require 'net/dns'
require 'capistrano/dsl'

def elastic_load_balancer(load_balancer_or_dns_name, *args)

  include Capistrano::DSL

  Aws.config.update(access_key_id:     fetch(:aws_access_key_id),
                    region:            fetch(:aws_region),
                    secret_access_key: fetch(:aws_secret_access_key))

  description = Aws::ElasticLoadBalancing::Client.new.describe_load_balancers
  load_balancer = description.load_balancer_descriptions.detect { |elb| elb.load_balancer_name == load_balancer_or_dns_name || elb.dns_name == load_balancer_or_dns_name }
  if load_balancer
    load_balancer.instances.map { |i| Aws::EC2::Instance.new(id: i.instance_id).data }.each do |instance|
        next if instance.state.name.to_s != 'running'
        hostname = if instance.vpc_id
          instance.private_ip_address
        else
          instance.public_ip_address || instance.private_ip_address
        end
        server(hostname, *args)
    end
  else
    raise "EC2 Load Balancer not found for #{load_balancer_or_dns_name} in region #{fetch(:aws_region)}"
  end
end
