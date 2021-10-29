# terraform-metal-securedrop-staging

Terraform module for standing up a SecureDrop staging environment at
Equinix Metal (fka Packet).  After you've run `terraform apply` and (~15
minutes later) cloud-init has completed, you'll have (e.g.):

```sh-session
$ ssh -L 5900:localhost:5902 root@139.178.89.89
[...]
root@sd-staging:~# virsh list
 Id   Name                                State
---------------------------------------------------
 1    libvirt-staging-focal_app-staging   running
 2    libvirt-staging-focal_mon-staging   running
 4    tails                               running

root@sd-staging:~# virsh vncdisplay tails
127.0.0.1:2
```

Your Tails domain will be available via VNC at `localhost:5900` with the
VNC password `tails`.

## Troubleshooting

Use `journalctl [-f]` to check on the progress of cloud-init.
