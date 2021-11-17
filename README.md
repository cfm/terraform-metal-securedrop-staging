# terraform-metal-securedrop-staging

Terraform module for standing up a SecureDrop staging environment at
Equinix Metal (fka Packet).

**Warning: Using this and keeping it running will incur costs (see below).**

Prerequisites:
1. [Install the latest stable version of Terraform](https://www.terraform.io/downloads.html)
2. [Create an Equinix Metal account](https://metal.equinix.com/)
3. Create a project (you will need its name)
4. Create an account-level personal API key (you will need its token)

Usage:

Define a `terraform.tfvars` like:

```hcl
# REQUIRED:
auth_token = "your Equinix Metal API token here"
metro      = "two-letter metro code here"  # https://metal.equinix.com/developers/api/metros/
project    = "name of your configured Equinix Metal project here"

# OPTIONAL:
plan = "if you want something other than c3.small.x86"  # https://metal.equinix.com/developers/api/plans/
```

After you've run `terraform init && terraform apply`, you should see your
server's IP address in the output. After `cloud-init` has completed, you
can start a session like so:

```sh-session
$ terraform init
[...]
$ terraform apply
[...]
metal_device.sd-staging: Still creating... [2m0s elapsed]
metal_device.sd-staging: Still creating... [2m10s elapsed]
metal_device.sd-staging: Still creating... [2m20s elapsed]
metal_device.sd-staging: Creation complete after 2m22s [id=04baac1e-f733-4a97-8d5e-470aa6d6d483]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

ip_address = "<your IP>"
$ ssh -L 5900:localhost:5902 root@<your IP>
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

If you used the SSH invocation above, your Tails domain will be available via
VNC at `localhost:5900` with the VNC password `tails`. You can use a VNC client
like `vinagre` (connect using the VNC protocol).

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
