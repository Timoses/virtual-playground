# Virtual playground

* Currently only supports VirtualBox Vagrant provider

![Network overview](docs/network.png)

## Kubernetes

First start up the infrastructure components:
```
vagrant up router
vagrant up infra
```

### Talos

`vagrant up /kubernetes-talos/` - bring up all kubernetes hosts
