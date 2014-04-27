# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define "admin" , primary: true do |admin|
    admin.vm.box = "centos-6.5-x86_64"
    admin.vm.box_url = "https://dl.dropboxusercontent.com/s/np39xdpw05wfmv4/centos-6.5-x86_64.box"

    admin.vm.hostname = "admin.example.com"

    admin.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=777","fmode=777"]
    admin.vm.synced_folder "./installer", "/software"
  
    admin.vm.network :private_network, ip: "192.168.231.10"
    if defined? VagrantPlugins::HostsUpdater
      config.hostsupdater.aliases = ["admin"]
    end
    
    admin.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "2048"]
      vb.customize ["modifyvm", :id, "--name", "admin"]
    end
  
    admin.vm.provision :shell, :inline => "ln -sf /vagrant/puppet/hiera.yaml /etc/puppet/hiera.yaml"
    
    admin.vm.provision :puppet do |puppet|
      puppet.manifests_path    = "puppet/manifests"
      puppet.module_path       = "puppet/modules"
      puppet.manifest_file     = "site.pp"
      puppet.options           = "--verbose --hiera_config /vagrant/puppet/hiera.yaml"
  
      puppet.facter = {
        "environment"                     => "development",
        "vm_type"                         => "vagrant",
        "override_weblogic_user"          => "wls",
        "override_weblogic_domain_folder" => "/opt/oracle/wlsdomains",
      }
      
    end
  
  end

end
