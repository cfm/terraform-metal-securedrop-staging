# terraform-metal-securedrop-staging

Terraform module for standing up a SecureDrop staging environment at
Equinix Metal (fka Packet).

Define a `terraform.tfvars` like:

```hcl
# REQUIRED:
auth_token = "your Equinix Metal token here"
metro      = "two-letter metro code here"  # https://metal.equinix.com/developers/api/metros/
project    = "name of your configured Equinix Metal project here"

# OPTIONAL:
plan = "if you want something other than c3.small.x86"  # https://metal.equinix.com/developers/api/plans/
```

After you've run `terraform init && terraform apply` and (~5 minutes
later) cloud-init has completed, you'll have (e.g.):

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

* By default, each instance of this module provisions a
  ~~[`t1.small.x86`][t1.small.x86]~~ [c3.small.x86][c3.small.x86]
  ([alas][equinix-feedback-thread]) server at ~~$0.07~~ $0.50 per hour.
  A running instance therefore costs:

| Period | Cost |
| --- | --- |
| Hourly | ~~$0.07~~ $0.50 |
| Daily | ~~$1.68~~ $12.00 |
| Monthly | ~~$50.40~~ $360.00 |


[equinix-feedback-thread]: https://feedback.equinixmetal.com/servers-and-configs/p/mini-servers-to-give-the-sweet-sweet-taste-of-equinix-metal
[c3.small.x86]: https://metal.equinix.com/developers/docs/servers/server-specs/#c3smallx86
[t1.small.x86]: https://metal.equinix.com/developers/docs/servers/server-specs/#t1smallx86
