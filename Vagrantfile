# vi: filetype=ruby

# Network Diagram
# https://drive.google.com/open?id=15pEGT6TB5kWFl9kXrpdu7VqCEHKykfuj

k8s_hosts = [
  'kubernetes-talos-master-1'
]

Vagrant.configure("2") do |config|
  config.vm.box = "centos/8"

  if Vagrant.has_plugin?("vagrant-vbguest")
    # Disable VirtualBox auto update
    # It significantly increases VMs
    # provisioning time.
    config.vbguest.auto_update = false
  end

  config.vm.define "client" do |client|
    client.vm.hostname = "client"
    client.vm.network "private_network", ip: "192.168.101.2",
        virtualbox__intnet: "client", auto_config: false
  end

  config.vm.define "infra" do |infra|
    infra.vm.hostname = "infra"
    infra.vm.network "private_network", ip: "192.168.102.2",
        virtualbox__intnet: "infra", auto_config: false
  end

  config.vm.define "router" do |router|
    router.vm.hostname = "router"
    router.vm.network "private_network", ip: "192.168.101.1",
        virtualbox__intnet: "client"
    router.vm.network "private_network", ip: "192.168.102.1",
        virtualbox__intnet: "infra"
  end

  k8s_hosts.each do |k8s|
    config.vm.define k8s do |kube|
      kube.vm.provider :virtualbox do |vb|

        # Attach first NIC to infra network
        vb.customize [
          'modifyvm', :id,
          '--nic1', 'intnet',
          '--intnet1', 'infra',
          '--macaddress1', '52540072FE6E',
          '--boot1', 'disk',
          '--boot2', 'net',
          '--boot3', 'none',
          '--boot4', 'none'
        ]

        # Attach new disk (replace Vagrant-placed one)
        k8s_disk = "./#{k8s}.vdi"
        vb.customize [
          'createmedium',
          '--filename', k8s_disk,
          '--size', 4 * 1024,
          '--format', 'vdi',
          '--variant', 'Fixed'
        ] unless FileTest.exists?(k8s_disk)
        vb.customize [
          'storageattach', :id,
          '--storagectl', 'IDE',
          '--port', '0',
          '--device', '0',
          '--medium', k8s_disk,
          '--type', 'hdd'
        ]
      end
    end
  end

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "ansible/playbook.yml"
    ansible.verbose = "vv"
  end
end

