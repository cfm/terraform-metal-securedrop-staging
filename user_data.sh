#!/bin/bash
set -eux -o pipefail

# Configuration prerequisites:
sudo apt-get update
sudo apt-get install --yes \
    jq \
    locales-all

# General parameters:
export HOME=/root
export WORKDIR="${HOME}/securedrop"

# Tails parameters:
export TAILS_TAGS_ENDPOINT="https://gitlab.tails.boum.org/api/v4/projects/tails%2Ftails/repository/tags"
export TAILS_LATEST_TAG=$(curl $TAILS_TAGS_ENDPOINT | jq -r ".[0].name")

export TAILS_IMG=/tails.img
export TAILS_IMG_SIG="${TAILS_IMG}.sig"
export TAILS_IMG_URL="https://mirrors.edge.kernel.org/tails/stable/tails-amd64-${TAILS_LATEST_TAG}/tails-amd64-${TAILS_LATEST_TAG}.img"
export TAILS_KEY_URL="https://tails.net/tails-signing.key"

# --- SECUREDROP PREREQUISITES ---
#
# For the sake of easy cross-referencing, commands here are replicated as
# faithfully as possible from the SecureDrop documentation as cited, even
# when it would be easier to split them over multiline YAML strings, when
# their "sudo" prefixes are no-ops under cloud-init, etc.

# https://docs.securedrop.org/en/stable/development/setup_development.html#ubuntu-or-debian-gnu-linux
# https://docs.docker.com/engine/install/debian/
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# https://docs.securedrop.org/en/stable/development/setup_development.html
sudo apt-get install -y build-essential libssl-dev libffi-dev python3-dev dpkg-dev git linux-headers-$(uname -r)

sudo apt-get install -y python3-pip
python3 -m pip install --upgrade pip virtualenv

# https://docs.securedrop.org/en/stable/development/virtual_environments.html#debian-stable-setup
sudo apt-get install -y vagrant libvirt-daemon-system qemu-kvm virt-manager
sudo apt-get install -y ansible rsync
apt-get remove -y vagrant-libvirt  # so that we can then...
vagrant plugin install vagrant-libvirt \
    --plugin-version 0.7.0  # vagrant-libvirt/vagrant-libvirt#1519
vagrant plugin install vagrant-mutate

sudo rmmod kvm_intel
sudo rmmod kvm
sudo modprobe kvm
sudo modprobe kvm_intel

echo 'export VAGRANT_DEFAULT_PROVIDER=libvirt' >> ~/.bashrc
export VAGRANT_DEFAULT_PROVIDER=libvirt

vagrant box add --provider virtualbox bento/ubuntu-20.04
vagrant mutate bento/ubuntu-20.04 libvirt

# -- SECUREDROP WORKSPACE ---
git clone https://github.com/freedomofpress/securedrop.git "$WORKDIR"

apt-get install -y enchant-2
apt-get install -y rustc

cd "$WORKDIR" && make build-debs-notest && make build-debs-ossec-notest

# Under the hood, the "libvirt-staging-focal" Molecule scenario will create
# the "libvirt-vagrant" network to which we'll attach our Tails domain.
cd "$WORKDIR" && make staging

# --- TAILS ---
curl -o "$TAILS_IMG" "$TAILS_IMG_URL"
curl -o "$TAILS_IMG_SIG" "${TAILS_IMG_URL}.sig"
curl --silent "$TAILS_KEY_URL" | gpg --import
gpg --verify "$TAILS_IMG_SIG" "$TAILS_IMG"
truncate --size ">16G" "$TAILS_IMG"
virt-install \
    --boot hd \
    --disk "${TAILS_IMG},bus=usb,removable=on" \
    --graphics "spice,password=tails" \
    --import \
    --memory 4096 \
    --name tails \
    --network network=vagrant-libvirt \
    --noautoconsole \
    --os-type debian10 \
    --vcpus 2
