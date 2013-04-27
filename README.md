# The Prestige

This cookbook is designed to be make Amazon AMIs(link) for Chef roles.

## Usage

Let's say the you want to make an AMI out of a role for one of your web machines called `web.rb` and it has the following run-list:

`run_list "recipe[baseline::default]","recipe[web_app::app]"`

To make an ami, spint up an instance using knife with a rule-list parameter of

`recipe[the_prestige::default],role[web]`

Once the machine has done all of the normal processing that it would do, then it makes a call to Amazon to create an AMI of the machine. This process will cause the machine to reboot. Once the machine has rebooted, it will terminate itself.

It accomplishes the following:

- Figure out what ami name should be
    - image_name = role_name + datetime (for now, later do versions of recipes included)

- Check if an ami has already been created
    - `https://ec2.amazonaws.com/?Action=DescribeImages
        &ImageId.1={{ image_name }}-*
        &AUTHPARAMS`
    - If yes, terminate self
        -`https://ec2.amazonaws.com/?Action=TerminateInstances
            &InstanceId.1={{ instance_id }}
            &AUTHPARAMS`
    - If no, continue.

- Make call to amazon to create ami
    - https://ec2.amazonaws.com/?Action=CreateImage
        &Description={{ image_name }}
        &InstanceId={{ instance_id }}
        &Name={{ image_name }}
        &AUTHPARAMS

## Attributes

KEYS


 - chef runs on new machine
 - makes call to amazon to create ami of itself (this forces a reboot)
 - new machine shuts itself down
