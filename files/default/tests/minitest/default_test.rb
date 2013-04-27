require 'minitest/spec'

describe_recipe 'the_prestige::default' do

    include MiniTest::Chef::Assertions
    include MiniTest::Chef::Context
    include MiniTest::Chef::Resources

    it "should test your cookbook" do
        package('libxml2-dev').must_be_installed
        package('libxslt1-dev').must_be_installed
    end

end
