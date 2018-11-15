# -*- mode: ruby -*-
# vi: set ft=ruby :

require './plugins/vagrant-provision-reboot-plugin'
require 'ipaddr'
require 'yaml'

x = YAML.load_file('env.yaml')
puts "Config: #{x.inspect}\n\n"

Vagrant.configure("2") do |config|

  config.vm.define "kube-master" do |master|
    c = x.fetch('master')
    master.vm.box = x.fetch('box_image')
    master.vm.hostname = "kube-master"
    master.vm.network :private_network, ip: x.fetch('ip').fetch('master'), virtualbox__intnet: x.fetch('domain')
    master.vm.network :forwarded_port, guest: 8001, host: 8001
    master.vm.provider :virtualbox do |vb|
      vb.name = "kube-master"+"."+x.fetch('domain')
      vb.cpus = c.fetch('cpus')
      vb.memory = c.fetch('memory')
      vb.customize [
        'modifyvm', :id,
        '--natdnshostresolver1', 'on'
      ]
      vb.customize [
        'modifyvm', :id,
        '--natdnsproxy1', 'on'
      ]
    end
    master.vm.provision "shell", path: "variables.sh"
    master.vm.provision "shell", path: "scripts/all_01_set_my_user.sh"
    master.vm.provision "shell", path: "scripts/all_02_general_provision.sh"
    master.vm.provision "shell", path: "scripts/all_03_kubernetes_prep.sh"
    master.vm.provision :unix_reboot
    master.vm.provision "file", source: "files/kube-flannel.yml", destination: "/tmp/kube-flannel.yml"
    master.vm.provision "shell", path: "scripts/master_01_kubernetes_cluster.sh"
    master.vm.provision "shell", path: "scripts/all_04_cleanup.sh"
    master.vm.provision "file", source: "files/dashboard-adminuser.yml", destination: "/tmp/dashboard-adminuser.yml"
    master.vm.provision "file", source: "files/dashboard-adminuser-rbac.yml", destination: "/tmp/dashboard-adminuser-rbac.yml"
    master.vm.provision "file", source: "scripts/others_kubernetes_deploy_dashboard.sh", destination: "/tmp/others_kubernetes_deploy_dashboard.sh"
  end

  node_ip = IPAddr.new(x.fetch('ip').fetch('node'))
  (1..x.fetch('node').fetch('count')).each do |i|
    c = x.fetch('node')
    hostname = "kube-work%02d" % i
    config.vm.define hostname do |worker|
      worker.vm.box = x.fetch('box_image')
      worker.vm.hostname = hostname
      worker.vm.network :private_network, ip: IPAddr.new(node_ip.to_i + i - 1, Socket::AF_INET).to_s, virtualbox__intnet: x.fetch('domain')
      worker.vm.provider :virtualbox do |vb|
        vb.name = hostname+"."+x.fetch('domain')
        vb.cpus = c.fetch('cpus')
        vb.memory = c.fetch('memory')
      vb.customize [
        'modifyvm', :id,
        '--natdnshostresolver1', 'on'
      ]
      vb.customize [
        'modifyvm', :id,
        '--natdnsproxy1', 'on'
      ]
      end
      worker.vm.provision "shell", path: "variables.sh"
      worker.vm.provision "shell", path: "scripts/all_01_set_my_user.sh"
      worker.vm.provision "shell", path: "scripts/all_02_general_provision.sh"
      worker.vm.provision "shell", path: "scripts/all_03_kubernetes_prep.sh"
      worker.vm.provision :unix_reboot
      worker.vm.provision "shell", path: "scripts/worker_01_kubernetes_cluster_add.sh"
      worker.vm.provision "shell", path: "scripts/all_04_cleanup.sh"
    end
  end
end