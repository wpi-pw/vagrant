# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Vagrantfile using wpi/box
# Check out https://github.com/wpi-pw/box to learn more about wpi/box
#
# Author: Dima Minka
# URL: https://wpi.pw/box/
#
# File Version: 1.2.2

require 'yaml'

# Load the settings file
if(File.exist?("wpi-custom.yml"))
  settings = YAML.load_file(File.join(File.dirname(__FILE__), "wpi-custom.yml"))
else
  settings = YAML.load_file(File.join(File.dirname(__FILE__), "wpi-default.yml"))
end

# Detect host OS for different folder share configuration
module OS
  def OS.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end

  def OS.mac?
    (/darwin/ =~ RUBY_PLATFORM) != nil
  end

  def OS.unix?
    !OS.windows?
  end

  def OS.linux?
    OS.unix? and not OS.mac?
  end
end

Vagrant.configure("2") do |config|
  config.vm.box = settings["vm_box"] ||= "wpi/box"
  config.vm.provider settings["provider"] ||= "virtualbox"

  [
    { :name => "vagrant-hostmanager", :version => ">= 1.8.9" },
    { :name => "vagrant-vbguest", :version => ">= 0.16.0" },
    { :name => "vagrant-cachier", :version => ">= 1.2.1"}
  ].each do |plugin|

  Vagrant::Plugin::Manager.instance.installed_specs.any? do |s|
    req = Gem::Requirement.new([plugin[:version]])
      if (not req.satisfied_by?(s.version)) && plugin[:name] == s.name
        raise "#{plugin[:name]} #{plugin[:version]} is required. Please run `vagrant plugin install #{plugin[:name]}`"
      end
    end
  end

  config.cache.scope = :box

  # Vagrant hardware settings
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--memory", settings["memory"] ||= "2048"]
    vb.customize ["modifyvm", :id, "--cpus", settings["cpus"] ||= "2"]
  end

  config.vm.provider "parallels" do |v|
  v.memory = settings["memory"] ||= "2048"
  v.cpus = settings["cpus"] ||= "2"
  end

  # vagrant-hostmanager config (https://github.com/smdahlen/vagrant-hostmanager)
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true

  config.vm.define "project" do |node|
    node.vm.hostname = settings['hostname'] ||= 'wpi-box'
    node.vm.network :private_network, ip: settings['ip'] ||= '192.168.13.100'

    settings['apps'].each do |app|
      node.hostmanager.aliases = app['host']
    end

    node.hostmanager.aliases = [settings['apps'].map{|l| l['host']}]

    config.vm.network :forwarded_port, guest: 80, host: 8080
    config.vm.network :forwarded_port, guest: 443, host: 443
  end

  # Configure The Public Key For SSH Access
  if settings.include? 'authorize'
    if File.exists? File.expand_path(settings["authorize"])
      config.vm.provision "shell" do |s|
        s.inline = "echo $1 | grep -xq \"$1\" /home/vagrant/.ssh/authorized_keys || echo \"\n$1\" | tee -a /home/vagrant/.ssh/authorized_keys"
        s.args = [File.read(File.expand_path(settings["authorize"]))]
      end
    end
  end

  # Copy The SSH Private Keys To The Box
  if settings.include? 'keys'
    if settings["keys"].to_s.length == 0
      puts "Check your wpi-default.yml file, you have no private key(s) specified."
      exit
    end
    settings["keys"].each do |key|
      if File.exists? File.expand_path(key)
        config.vm.provision "shell" do |s|
          s.privileged = false
          s.inline = "echo \"$1\" > /home/vagrant/.ssh/$2 && chmod 600 /home/vagrant/.ssh/$2"
          s.args = [File.read(File.expand_path(key)), key.split('/').last]
        end
      else
        puts "Check your wpi-default.yml file, the path to your private key does not exist."
        exit
      end
    end
  end

  # Disabling the default /vagrant share
  config.vm.synced_folder '.', '/vagrant', disabled: true

  # Register The Configured Shared Folder
  config.vm.synced_folder "apps", "/home/vagrant/apps", owner: "www-data", group: "www-data", disabled: false, create: true

  config.ssh.forward_agent = true

  # Configure The email
  if settings["wpi_email"].to_s.length == 0
    puts "Check your wpi-default.yml file, you have no wpi_email specified."
    exit
  else
    config.vm.provision "shell" do |s|
      s.inline = "echo $1$2 | grep -xq -s \"$1$2\" /home/vagrant/.bash_profile || echo \"\n$1$2\" | tee -a /home/vagrant/.bash_profile"
      s.args   = ['export wpi_email=', settings["wpi_email"]]
    end
  end

  # Configure The user
  if settings["wpi_user"].to_s.length == 0
    puts "Check your wpi-default.yml file, you have no wpi_user specified."
    exit
  else
    config.vm.provision "shell" do |s|
      s.inline = "echo $1$2 | grep -xq -s \"$1$2\" /home/vagrant/.bash_profile || echo \"\n$1$2\" | tee -a /home/vagrant/.bash_profile"
      s.args   = ['export wpi_user=', settings["wpi_user"]]
    end
  end

  if settings["vm_box"] == "wpi/box"
    # Basic provison for new box
    $script = <<-SCRIPT
    source /home/vagrant/.bash_profile
    echo "=============================="
    echo "You can replace $wpi_user with your username & $wpi_email by your email in wpi-default.yml"
    echo "=============================="
    sudo chown vagrant:vagrant /home/vagrant/.[^.]*
    sudo echo -e "source ~/.bashrc\n" >> /home/vagrant/.bash_profile
    sudo echo -e "[user]\n\tname = $wpi_user\n\temail = $wpi_email" > /home/vagrant/.gitconfig

    echo "=============================="
    echo "Copy gitconfig and bash_profile to www-data directory"
    echo "=============================="
    sudo cp /home/vagrant/{.gitconfig,.bash_profile} /var/www
    sudo chown www-data:www-data /var/www/.[^.]*

    echo "=============================="
    echo "copy keys from vagrant directory to www-data and root"
    echo "=============================="
    ssh-keyscan -H bitbucket.org >> /home/vagrant/.ssh/known_hosts
    ssh-keyscan -H github.com >> /home/vagrant/.ssh/known_hosts
    sudo cp -r /home/vagrant/.ssh /var/www/.ssh
    sudo chown -R www-data:www-data /var/www/.ssh

    echo "=============================="
    echo "move files to vagrant apps and make the symlink"
    echo "=============================="
    sudo mv /var/www/{.,}* /home/vagrant/apps 2>/dev/null
    sudo mv /var/www /var/www-disabled 2>/dev/null
    sudo ln -s /home/vagrant/apps /var/www
    SCRIPT
    config.vm.provision "shell", inline: $script
  end
end
