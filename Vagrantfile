# Network Diagram
# https://drive.google.com/open?id=15pEGT6TB5kWFl9kXrpdu7VqCEHKykfuj

Vagrant.configure("2") do |config|
  config.vm.provision "shell", inline: "echo Hello"

  config.vm.define "host1" do |host1|
    host1.vm.box = "geerlingguy/centos7"
  end
end

