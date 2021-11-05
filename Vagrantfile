# -*- mode: ruby -*-
# vi: set ft=ruby :

require './plugins/vagrant-provision-reboot-plugin'
require 'ipaddr'
require 'yaml'

x = YAML.load_file('env.yaml')
puts "Config: #{x.inspect}\n\n"

Vagrant.configure("2") do |config|

  config.vm.define "control_plane" do |control_plane|
    c = x.fetch('control_plane')
    control_plane.disksize.size = c.fetch('disk_size')
    control_plane.vm.box = x.fetch('box_image')
    control_plane.vm.hostname = "control_plane"

    # control_plane.vm.network :private_network, ip: x.fetch('ip').fetch('control_plane'), virtualbox__intnet: x.fetch('domain')
    control_plane.vm.network :private_network, ip: x.fetch('ip').fetch('control_plane')

    # control_plane.vm.network :public_network, bridge: "en0: Wi-Fi (AirPort)", auto_config: true

    ## 31557 is the port for Dashboard
    control_plane.vm.network :forwarded_port, guest: x.fetch('ports').fetch('dashboard_port'), host: x.fetch('ports').fetch('dashboard_port')
    ## 31558 is the port for Kibana
    control_plane.vm.network :forwarded_port, guest: 5601, host: 31558

    ## 31559 is the port for Prometheus server if we move it to port 81
    control_plane.vm.network :forwarded_port, guest: 81, host: 31559

    ## this port might change - 32185 for wordpress
    control_plane.vm.network :forwarded_port, guest: x.fetch('ports').fetch('wordpress_port'), host: x.fetch('ports').fetch('wordpress_port')
    control_plane.vm.provider :virtualbox do |vb|
      # vb.name = "control_plane"+"."+x.fetch('domain')
      vb.name = "control_plane"
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
    control_plane.vm.provision "shell", path: "variables.sh"
    control_plane.vm.provision "shell", path: "scripts/all_01_set_my_user.sh"
    control_plane.vm.provision "shell", path: "scripts/all_02_general_provision.sh"
    control_plane.vm.provision "shell", path: "scripts/all_03_kubernetes_prep.sh"
    control_plane.vm.provision :unix_reboot
    control_plane.vm.provision "file", source: "files/kube-flannel.yml", destination: "/tmp/kube-flannel.yml"
    control_plane.vm.provision "shell", path: "scripts/control_plane_01_kubernetes_cluster.sh"
    control_plane.vm.provision "shell", path: "scripts/all_04_cleanup.sh"
    # Files below will be used to set up Dashboard together with the instructions in zero_others_kubernetes_stuff.sh
    control_plane.vm.provision "file", source: "files/kubernetes-dashboard.yml", destination: "/tmp/kubernetes-dashboard.yml"
    control_plane.vm.provision "file", source: "files/dashboard-adminuser.yml", destination: "/tmp/dashboard-adminuser.yml"
    control_plane.vm.provision "file", source: "files/dashboard-adminuser-rbac.yml", destination: "/tmp/dashboard-adminuser-rbac.yml"
    # Files below will be used to set up ELK together with the instructions in zero_others_kubernetes_stuff.sh
    control_plane.vm.provision "file", source: "files/persistent-volume-elk-01.yml", destination: "/tmp/persistent-volume-elk-01.yml"
    control_plane.vm.provision "file", source: "files/persistent-volume-elk-02.yml", destination: "/tmp/persistent-volume-elk-02.yml"
    control_plane.vm.provision "file", source: "files/elk_01_k8s_global.tar.gz", destination: "/tmp/elk_01_k8s_global.tar.gz"
    control_plane.vm.provision "file", source: "files/elk_02_elasticsearch.tar.gz", destination: "/tmp/elk_02_elasticsearch.tar.gz"
    control_plane.vm.provision "file", source: "files/elk_03_kibana.tar.gz", destination: "/tmp/elk_03_kibana.tar.gz"
    control_plane.vm.provision "file", source: "files/elk_04_beats_init.tar.gz", destination: "/tmp/elk_04_beats_init.tar.gz"
    control_plane.vm.provision "file", source: "files/elk_05_beats_agents.tar.gz", destination: "/tmp/elk_05_beats_agents.tar.gz"
    # Files below will be used to set up Ceph
    control_plane.vm.provision "file", source: "files/rook_ceph_grafanaingress.tar.gz", destination: "/tmp/rook_ceph_grafanaingress.tar.gz"
    control_plane.vm.provision "file", source: "files/wordpress.tar.gz", destination: "/tmp/wordpress.tar.gz"
    # zero_others_kubernetes_stuff.sh
    control_plane.vm.provision "file", source: "scripts/zero_others_kubernetes_stuff.sh", destination: "/tmp/zero_others_kubernetes_stuff.sh"
    # control_plane.vm.synced_folder "files/", "/tmp/files"
    # control_plane.vm.synced_folder "scripts/", "/tmp/scripts"

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