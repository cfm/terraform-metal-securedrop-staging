# terraform-metal-securedrop-staging

Terraform module for standing up a SecureDrop staging environment at
Equinix Metal (fka Packet).

**WARNING: Using this and keeping it running will incur costs (see below).**

## Prerequisites

1. [Install the latest stable version of Terraform](https://www.terraform.io/downloads.html)
2. [Create an Equinix Metal account](https://metal.equinix.com/)
3. Create a project (you will need its name)
4. Create an account-level personal API key (you will need its token)

## Usage

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

The `app-staging` applications (Source and Journalist Interfaces) will
be reachable via the same [instructions][sd-staging] used to connect to
any other SecureDrop staging environment.

[sd-staging]: https://docs.securedrop.org/en/stable/development/virtual_environments.html#staging

### Expert usage: SecureDrop production VMs

You can also use this setup as the basis for a ["production VM"][sd-prod]
installation of SecureDrop:

> a production installation with all of the system hardening active, but
> virtualized, rather than running on hardware.

To do so, pick up the instructions from the section ["Install from an
Admin Workstation VM"][install-from-admin-workstation-vm]. First,
provision the production VMs alongside the existing staging VMs:

```sh-session
$ ssh -L 5900:localhost:5902 root@<your IP>
[...]
root@sd-staging:~# cd securedrop
root@sd-staging:~# source .venv/bin/activate
(.venv) root@sd-staging:~/securedrop# molecule create -s libvirt-prod-focal
```

Then follow the rest of the instructions on the Tails domain over VNC as
described above. You'll probably find it convenient to fetch [Vagrant's
base-box private key][vagrant-keypair] for SSH from the Tails domain, e.g.:

```sh-session
amnesia@amnesia:~$ wget -O .ssh/id_rsa https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant
amnesia@amnesia:~$ chmod 600 .ssh/id_rsa
```

**NOTE.** You _must_ configure Tails persistence before `securedrop-admin
setup`, even if you don't actually require your `securedrop` clone to persist
across reboots of the Tails domain (for example, during one-off testing).
Without persistence configured, the `setup` action will bog down the Tails RAM
disk (with the recommended 2 GB of RAM), and the domain is likely to lock up.

For `securedrop-admin sdconfig`, you'll need to be ready with the following
values:

```sh-session
amnesia@amnesia:~$ ./securedrop-admin sdconfig
Username for SSH access to the servers: vagrant
[...]
Local IPv4 address for the Application Server: # from "virsh domifaddr libvirt-prod-focal_app-prod"
Local IPv4 address for the Monitor Server: # from "virsh domifaddr libvirt-prod-focal_mon-prod"
Hostname for Application Server: app-prod
Hostname for Monitor Server: mon-prod
[...]
```

[install-from-admin-workstation-vm]: https://docs.securedrop.org/en/stable/development/virtual_environments.html#install-from-an-admin-workstation-vm
[sd-prod]: https://docs.securedrop.org/en/stable/development/virtual_environments.html#production

### Resetting a Molecule scenario

To reset the staging or production VM scenarios, you'll need to do a bit of
cleanup, e.g.:

```sh-session
root@sd-staging:~# cd securedrop
root@sd-staging:~/securedrop# source .venv/bin/activate
(.venv) root@sd-staging:~/securedrop# molecule destroy -s libvirt-prod-focal
(.venv) root@sd-staging:~/securedrop# virsh undefine libvirt-prod-focal_app_prod
(.venv) root@sd-staging:~/securedrop# virsh undefine libvirt-prod-focal_mon_prod
(.venv) root@sd-staging:~/securedrop# virsh vol-delete --pool default libvirt-prod-focal_app-prod
(.venv) root@sd-staging:~/securedrop# virsh vol-delete --pool default libvirt-prod-focal_mon-prod
```

Then you can redo:

```sh-session
(.venv) root@sd-staging:~/securedrop# molecule create -s libvirt-prod-focal
```

## Other things to know

- You can use `journalctl [-f]` to check on the progress of cloud-init.

- By default, each instance of this module provisions a
  ~~[`t1.small.x86`][t1.small.x86]~~ [c3.small.x86][c3.small.x86]
  ([alas][equinix-feedback-thread]) server at ~~$0.07~~ $0.50 per hour.
  A running instance therefore costs:

| Period  | Cost               |
| ------- | ------------------ |
| Hourly  | ~~$0.07~~ $0.50    |
| Daily   | ~~$1.68~~ $12.00   |
| Monthly | ~~$50.40~~ $360.00 |

[equinix-feedback-thread]: https://feedback.equinixmetal.com/servers-and-configs/p/mini-servers-to-give-the-sweet-sweet-taste-of-equinix-metal
[c3.small.x86]: https://metal.equinix.com/developers/docs/servers/server-specs/#c3smallx86
[t1.small.x86]: https://metal.equinix.com/developers/docs/servers/server-specs/#t1smallx86
[vagrant-keypair]: https://github.com/hashicorp/vagrant/tree/main/keys
