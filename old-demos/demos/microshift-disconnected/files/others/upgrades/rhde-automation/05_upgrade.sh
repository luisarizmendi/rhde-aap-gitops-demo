#!/bin/bash

script_dir="$(dirname "$0")"
repo_tar="/tmp/usb-autoconfigure/rhde/rhde-image.tar"
repo_dir="/run/install/repo/ostree"

if [ ! -d $repo_dir ]; then
    mkdir -p  $repo_dir
fi

echo "Getting the new image"
tar xvf $repo_tar -C $repo_dir

echo "Upgrading..."

ostree pull-local $repo_dir/repo
rpm-ostree update --preview
rpm-ostree update
rpm-ostree status

echo "Rebooting..."
sleep 5
reboot



