# -*- mode: ruby -*-
# vi: set ft=ruby :

require './plugins/vagrant-provision-reboot-plugin'
require 'ipaddr'
require 'yaml'

x = YAML.load_file('env.yaml')
puts "Config: #{x.inspect}\n\n"

Vagrant.configure("2") do |config|

  config.vm.define "master" do |master|
    c = x.fetch('master')
    master.disksize.size = "40GB"
    master.vm.box = x.fetch('box_image')
    master.vm.hostname = "master"
    # master.vm.network :private_network, ip: x.fetch('ip').fetch('master'), virtualbox__intnet: x.fetch('domain')
    master.vm.network :private_network, ip: x.fetch('ip').fetch('master')
    # master.vm.network :public_network, bridge: "en0: Wi-Fi (AirPort)", auto_config: true
    ## 31557 is the port for Dashboard
    master.vm.network :forwarded_port, guest: 31557, host: 31557
    ## 31558 is the port for Kibana
    master.vm.network :forwarded_port, guest: 5601, host: 31558
    ## 31559 is the port for Prometheus server if we move it to port 81
    master.vm.network :forwarded_port, guest: 81, host: 31559
    master.vm.provider :virtualbox do |vb|
      # vb.name = "master"+"."+x.fetch('domain')
      vb.name = "master"
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
    # Files below will be used to set up Dashboard together with the instructions in zero_others_kubernetes_stuff.sh
    master.vm.provision "file", source: "files/kubernetes-dashboard.yml", destination: "/tmp/kubernetes-dashboard.yml"
    master.vm.provision "file", source: "files/dashboard-adminuser.yml", destination: "/tmp/dashboard-adminuser.yml"
    master.vm.provision "file", source: "files/dashboard-adminuser-rbac.yml", destination: "/tmp/dashboard-adminuser-rbac.yml"
    # Files below will be used to set up ELK together with the instructions in zero_others_kubernetes_stuff.sh
    master.vm.provision "file", source: "files/persistent-volume-elk-01.yml", destination: "/tmp/persistent-volume-elk-01.yml"
    master.vm.provision "file", source: "files/persistent-volume-elk-02.yml", destination: "/tmp/persistent-volume-elk-02.yml"
    master.vm.provision "file", source: "files/elk_01_k8s_global.tar.gz", destination: "/tmp/elk_01_k8s_global.tar.gz"
    master.vm.provision "file", source: "files/elk_02_elasticsearch.tar.gz", destination: "/tmp/elk_02_elasticsearch.tar.gz"
    master.vm.provision "file", source: "files/elk_03_kibana.tar.gz", destination: "/tmp/elk_03_kibana.tar.gz"
    master.vm.provision "file", source: "files/elk_04_beats_init.tar.gz", destination: "/tmp/elk_04_beats_init.tar.gz"
    master.vm.provision "file", source: "files/elk_05_beats_agents.tar.gz", destination: "/tmp/elk_05_beats_agents.tar.gz"
    # Files below will be used to set up Ceph
    master.vm.provision "file", source: "files/ceph-cluster.yml", destination: "/tmp/ceph-cluster.yml"
    master.vm.provision "file", source: "files/ceph-dashboard-nodeip.yml", destination: "/tmp/ceph-dashboard-nodeip.yml"
    # zero_others_kubernetes_stuff.sh
    master.vm.provision "file", source: "scripts/zero_others_kubernetes_stuff.sh", destination: "/tmp/zero_others_kubernetes_stuff.sh"
    # master.vm.synced_folder "files/", "/tmp/files"
    # master.vm.synced_folder "scripts/", "/tmp/scripts"

  end

  node_ip = IPAddr.new(x.fetch('ip').fetch('node'))
  (1..x.fetch('node').fetch('count')).each do |i|
    c = x.fetch('node')
    hostname = "worker%02d" % i
    config.vm.define hostname do |worker|
      worker.vm.box = x.fetch('box_image')
      worker.vm.hostname = hostname
      # worker.vm.network :private_network, ip: IPAddr.new(node_ip.to_i + i - 1, Socket::AF_INET).to_s, virtualbox__intnet: x.fetch('domain')
      worker.vm.network :private_network, ip: IPAddr.new(node_ip.to_i + i - 1, Socket::AF_INET).to_s
      # worker.vm.network :public_network, bridge: "en0: Wi-Fi (AirPort)", auto_config: true
      worker.vm.provider :virtualbox do |vb|
        # vb.name = hostname+"."+x.fetch('domain')
        vb.name = hostname
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
      # worker.vm.synced_folder "files/", "/tmp/files"
      # worker.vm.synced_folder "scripts/", "/tmp/scripts"
    end
  end
end

# sudo ssh -i /home/aarba/.ssh/id_rsa -L 443:localhost:443 aarba@10.0.21.4
# sudo ssh -i /home/aarba/.ssh/id_rsa -L 443:localhost:443 aarba@10.107.40.114