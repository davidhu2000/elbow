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
  p '>>>>> Load Balancer'
  p load_balancer.load_balancer_name
  p load_balancer.dns_name

  if load_balancer
    load_balancer.instances.map { |i| Aws::EC2::Instance.new(id: i.instance_id).data }.each do |instance|
        next if instance.state.name.to_s != 'running'

        p '>>>>> Instances'
        p instance.vpc_id
        p instance.private_ip_address
        p instance.network_interfaces.first.private_ip_address
        p instance.network_interfaces.last.private_ip_address

        if instance.private_ip_address.include? '89'
          hostname = instance.network_interfaces.first.private_ip_address
        elsif instance.private_ip_address.include? '201'
          hostname = instance.network_interfaces.last.private_ip_address
        end

        server(hostname, *args)

        # begin
        #   puts '> Trying network_interfaces.first.private_ip_address'
        #   hostname = instance.network_interfaces.first.private_ip_address
        #   server(hostname, *args)
        # rescue
        #   puts '> Timeout error. Trying network_interfaces.last.private_ip_address'
        #   hostname = instance.network_interfaces.last.private_ip_address
        #   server(hostname, *args)
        # end

    end
  else
    raise "EC2 Load Balancer not found for #{load_balancer_or_dns_name} in region #{fetch(:aws_region)}"
  end
end
