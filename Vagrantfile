# -*- mode: ruby -*-
# vi: set ft=ruby :

require './plugins/vagrant-provision-reboot-plugin'
require 'ipaddr'
require 'yaml'

x = YAML.load_file('env.yaml')
puts "Config: #{x.inspect}\n\n"

Vagrant.configure("2") do |config|

  config.vm.define "controlplane" do |controlplane|
    c = x.fetch('controlplane')
    controlplane.disksize.size = c.fetch('disk_size')
    controlplane.vm.box = x.fetch('box_image')
    controlplane.vm.hostname = "controlplane"

    # controlplane.vm.network :private_network, ip: x.fetch('ip').fetch('controlplane'), virtualbox__intnet: x.fetch('domain')
    controlplane.vm.network :private_network, ip: x.fetch('ip').fetch('controlplane')

    # controlplane.vm.network :public_network, bridge: "en0: Wi-Fi (AirPort)", auto_config: true

    ## 31557 is the port for Dashboard
    controlplane.vm.network :forwarded_port, guest: x.fetch('ports').fetch('dashboard_port'), host: x.fetch('ports').fetch('dashboard_port')
    ## 31558 is the port for Kibana
    controlplane.vm.network :forwarded_port, guest: 5601, host: 31558

    ## 31559 is the port for Prometheus server if we move it to port 81
    controlplane.vm.network :forwarded_port, guest: 81, host: 31559

    ## this port might change - 32185 for wordpress
    controlplane.vm.network :forwarded_port, guest: x.fetch('ports').fetch('wordpress_port'), host: x.fetch('ports').fetch('wordpress_port')
    controlplane.vm.provider :virtualbox do |vb|
      # vb.name = "controlplane"+"."+x.fetch('domain')
      vb.name = "controlplane"
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
    controlplane.vm.provision "shell", path: "variables.sh"
    controlplane.vm.provision "shell", path: "scripts/all_01_set_my_user.sh"
    controlplane.vm.provision "shell", path: "scripts/all_02_general_provision.sh"
    controlplane.vm.provision "shell", path: "scripts/all_03_kubernetes_prep.sh"
    controlplane.vm.provision :unix_reboot
    controlplane.vm.provision "file", source: "files/kube-flannel.yml", destination: "/tmp/kube-flannel.yml"
    controlplane.vm.provision "shell", path: "scripts/controlplane_01_kubernetes_cluster.sh"
    controlplane.vm.provision "shell", path: "scripts/all_04_cleanup.sh"
    # Files below will be used to set up Dashboard together with the instructions in zero_others_kubernetes_stuff.sh
    controlplane.vm.provision "file", source: "files/kubernetes-dashboard.yml", destination: "/tmp/kubernetes-dashboard.yml"
    controlplane.vm.provision "file", source: "files/dashboard-adminuser.yml", destination: "/tmp/dashboard-adminuser.yml"
    controlplane.vm.provision "file", source: "files/dashboard-adminuser-rbac.yml", destination: "/tmp/dashboard-adminuser-rbac.yml"
    # Files below will be used to set up ELK together with the instructions in zero_others_kubernetes_stuff.sh
    controlplane.vm.provision "file", source: "files/persistent-volume-elk-01.yml", destination: "/tmp/persistent-volume-elk-01.yml"
    controlplane.vm.provision "file", source: "files/persistent-volume-elk-02.yml", destination: "/tmp/persistent-volume-elk-02.yml"
    controlplane.vm.provision "file", source: "files/elk_01_k8s_global.tar.gz", destination: "/tmp/elk_01_k8s_global.tar.gz"
    controlplane.vm.provision "file", source: "files/elk_02_elasticsearch.tar.gz", destination: "/tmp/elk_02_elasticsearch.tar.gz"
    controlplane.vm.provision "file", source: "files/elk_03_kibana.tar.gz", destination: "/tmp/elk_03_kibana.tar.gz"
    controlplane.vm.provision "file", source: "files/elk_04_beats_init.tar.gz", destination: "/tmp/elk_04_beats_init.tar.gz"
    controlplane.vm.provision "file", source: "files/elk_05_beats_agents.tar.gz", destination: "/tmp/elk_05_beats_agents.tar.gz"
    # Files below will be used to set up Ceph
    controlplane.vm.provision "file", source: "files/rook_ceph_grafanaingress.tar.gz", destination: "/tmp/rook_ceph_grafanaingress.tar.gz"
    controlplane.vm.provision "file", source: "files/wordpress.tar.gz", destination: "/tmp/wordpress.tar.gz"
    # zero_others_kubernetes_stuff.sh
    controlplane.vm.provision "file", source: "scripts/zero_others_kubernetes_stuff.sh", destination: "/tmp/zero_others_kubernetes_stuff.sh"
    # controlplane.vm.synced_folder "files/", "/tmp/files"
    # controlplane.vm.synced_folder "scripts/", "/tmp/scripts"

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

# export MYUSERNAME=
# sudo ssh -i /home/$MYUSERNAME/.ssh/id_rsa -L 443:localhost:443 $MYUSERNAME@10.0.21.4
# sudo ssh -i /home/$MYUSERNAME/.ssh/id_rsa -L 443:localhost:443 $MYUSERNAME@10.107.40.114