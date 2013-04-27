require 'aws-sdk'

module Prestige
  class PrestigeHandler < Chef::Handler

    def initialize(access_key_id, secret_access_key, image_name)
      @access_key_id = access_key_id
      @secret_access_key = secret_access_key
      @image_name = image_name
    end

    def report
      instance_id = node[:ec2][:instance_id]
      image_name = @image_name

      filename = '/etc/init.d/chef-client'
      original_contents = File.read(filename)
      new_contents = <<-EOH
#! /bin/sh

INSTANCE_ID=`ec2metadata | grep instance-id | awk -F- '{print $3}'`

if [ "i-$INSTANCE_ID" != "#{instance_id}" ]; then
    echo "This is a clone machine. Quitting..."
    return 1
fi
#{original_contents}
      EOH

      File.open(filename, 'w') { |file| file.write(new_contents) }


      AWS.config({
        :access_key_id => @access_key_id,
        :secret_access_key => @secret_access_key
      })

      ec2 = AWS::EC2.new()
      instance = ec2.instances[instance_id]

      if instance_id != 'vagrant_instance'
        # No AMI exists, create one
        Chef::Log.info("Creating AMI with name '#{image_name}'")

        require 'fileutils'
        FileUtils.mv("/etc/chef/base_validation.pem", "/etc/chef/validation.pem")

        ec2.images.create(:instance_id => instance_id,
                          :name => image_name)
      end
    end
  end
end