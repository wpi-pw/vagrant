# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Vagrantfile using wpi/box
# Check out https://github.com/wpi-pw/box to learn more about wpi/box
#
# Author: Dima Minka
# URL: https://wpi.pw/box/

require 'yaml'

# Load the settings file
if(File.exist?(File.join(File.dirname(__FILE__), "config.yml")))
  settings = YAML.load_file(File.join(File.dirname(__FILE__), "config.yml"))
end

Vagrant.configure("2") do |config|
  config.vm.box = settings["vm_box"] ||= "wpi/box"
  config.vm.provider settings["provider"] ||= "virtualbox"

  [
    { :name => "vagrant-hostsupdater", :version => ">= 1.1.1" }
  ].each do |plugin|

  Vagrant::Plugin::Manager.instance.installed_specs.any? do |s|
    req = Gem::Requirement.new([plugin[:version]])
      if (not req.satisfied_by?(s.version)) && plugin[:name] == s.name
        raise "#{plugin[:name]} #{plugin[:version]} is required. Please run `vagrant plugin install #{plugin[:name]}`"
      end
    end
  end

  # Vagrant hardware settings
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--memory", settings["memory"] ||= "2048"]
    vb.customize ["modifyvm", :id, "--cpus", settings["cpus"] ||= "2"]
  end

  config.vm.provider "parallels" do |v|
  v.memory = settings["memory"] ||= "2048"
  v.cpus = settings["cpus"] ||= "2"
  end

  config.vm.hostname = settings['hostname'] ||= 'wpi-box'
  config.vm.network :private_network, ip: settings['ip'] ||= '192.168.13.100'

  aliases = Array.new
  settings["apps"].each do |app|
    aliases.push(app["host"])
  end
  config.hostsupdater.aliases = aliases

  config.vm.network :forwarded_port, guest: 80, host: 8080
  config.vm.network :forwarded_port, guest: 443, host: 443

  # Copy The SSH Private/Public Keys To The Box
  if File.exists? File.expand_path(settings["id_rsa"])
    config.vm.provision "shell" do |s|
    s.privileged = false
    s.inline = "echo \"$1\" > /home/vagrant/.ssh/$2 && chmod 600 /home/vagrant/.ssh/$2"
    s.args = [File.read(File.expand_path(settings["id_rsa"])), settings["id_rsa"].split('/').last]
  end
  else
    puts "Check your config.yml file, the path to your private key does not exist."
    exit
  end
  if File.exists? File.expand_path(settings["id_rsa_pub"])
    config.vm.provision "shell" do |s|
    s.privileged = false
    s.inline = "echo \"$1\" > /home/vagrant/.ssh/$2 && chmod 600 /home/vagrant/.ssh/$2"
    s.args = [File.read(File.expand_path(settings["id_rsa_pub"])), settings["id_rsa_pub"].split('/').last]
  end
  else
    puts "The path to your public key does not exist... Put the file manually..."
  end

  # Sync current directory with vagrant
  config.vm.synced_folder ".", "/vagrant", type: "nfs", create: true  

  config.ssh.forward_agent = true

  # Running provision scripts for wpi-vagrant
  config.vm.provision "shell", inline: "bash <(curl -s -L wpi.pw/bin/vagrant/provision.sh)"

  # Running provision up scripts on every loading
  config.vm.provision "shell", inline: "bash <(curl -s -L wpi.pw/bin/vagrant/up.sh)", run: "always"
end
