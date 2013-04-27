#
# Cookbook Name:: the_prestige
# Recipe:: default
#
# Copyright 2013, Yipit
#
# All rights reserved - Do Not Redistribute
#


# aws-sdk dependencies
['libxml2-dev', 'libxslt1-dev', 'ruby1.9.3', 'make'].each do |pkg|
  p = package pkg do
    action :nothing
    retry_delay 5
    retries 2
  end
  p.run_action(:install)
end

chef_gem 'aws-sdk' do
  action :install
  version '1.8.3.1'
end

# if you want to debug something
# just uncomment this
#chef_gem 'ruby-debug' do
  #action :install
  #version '0.10.4'
#end

# and add this where you want to debug
# require 'ruby-debug'; debugger

directory "/etc/chef/handlers" do
  action :create
  owner "root"
  group "root"
  recursive true
end

cookbook_file "/etc/chef/handlers/prestige.rb" do
  source "prestige.rb"
  mode 00644
  owner "root"
  group "root"
end

image_name = node[:role] || ''

require 'fileutils'
# We want to make a copy of the validation key because we want it to be part of
# the image, but the process of this instance registering with chef will remove
# it. Thus, we make a copy that we can set back right before the image is made.
FileUtils.cp("/etc/chef/validation.pem", "/etc/chef/base_validation.pem")

require 'aws-sdk'


# getting the first level of registered recipe names for this role
recipes_running = node[:recipes]
recipes_running = recipes_running.map do |recipe_module_name|
  recipe_module_name.split('::')[0]
end
recipes_running = Set.new(recipes_running).to_a

# removing *this* cookbook, which should be 'the_prestige'
cookbook_name = "the_prestige"
#recipes_running.delete(cookbook_name.to_s)

cookbooks_running = node.cookbook_collection.values_at(*recipes_running)

# creating a name in the format "recipe1_0.0.0-recipe2_0.0.1"
recipes_names = cookbooks_running.map { |c| "#{c.name}_#{c.version}" }.join('-')

image_name << '-' << recipes_names

keys = data_bag_item('THE_PRESTIGE', 'KEYS')

AWS.config({
  :access_key_id => keys['ACCESS_KEY_ID'],
  :secret_access_key => keys['SECRET_ACCESS_KEY']
})

ec2 = AWS::EC2.new()

ami_created = node[:ami_created]
if ami_created
  # We've already created an AMI, terminate self
  while true
    matching_images = ec2.images.select do |img|
      # Keep sleeping until the image has been created or failed
      img.name and img.name.start_with?(image_name) and (img.state == :available or img.state == :failed)
    end
    if not matching_images.empty?
      Chef::Log.info("Found image matching '#{image_name}'. Terminating instance...")
      instance_id = node[:ec2][:instance_id]
      instance = ec2.instances[instance_id]
      instance.terminate
      exit 0
    else
      Chef::Log.info("Waiting for image creation to complete for '#{image_name}'. Sleeping...")
      sleep(10)
    end
  end
end

node.set[:ami_created] = true


chef_handler "Prestige::PrestigeHandler" do
  source "/etc/chef/handlers/prestige.rb"
  arguments [keys['ACCESS_KEY_ID'], keys['SECRET_ACCESS_KEY'], image_name]
  supports :report => true
  action :enable
end
