#!/usr/bin/env ruby
# encoding: utf-8

require 'berkshelf/vagrant'

Vagrant::Config.run do |config|

  config.vm.box = ""

  config.vm.provision :chef_solo do |chef|
    chef.json = {
      "username" => "vagrant",
      "ec2" => {
        "instance_id" => "vagrant_instance"
      }
    }

    chef.data_bags_path = "../../data_bags/staging"

    chef.log_level = "debug"

    chef.run_list = [
      "recipe[minitest-handler::default]",
      "recipe[the_prestige::default]"
    ]
  end

end
