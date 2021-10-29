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

## Things to know

* You can use `journalctl [-f]` to check on the progress of cloud-init.

* Each instance of this module provisions a [`t1.small.x86`][t1.small.x86]
  server at $0.07/hour.  A running instance therefore costs:

| Period | Cost |
| --- | --- |
| Hourly | $0.07 |
| Daily | $1.68 |
| Monthly | $50.40 |


[t1.small.x86]: https://metal.equinix.com/developers/docs/servers/server-specs/#t1smallx86
