#!/bin/bash

set -e

device='/dev/sdb';
vgName='data';
lvName='data00';
fsType='xfs';
mountTo='/data00';

echo 'Starting up LVM script';

devicePartition="${device}1";
mountFrom="/dev/mapper/$vgName-$lvName";
mkfsCommand="mkfs.$fsType";

command -v "$mkfsCommand" >/dev/null 2>&1 || {
  echo "$fsType is not a supported filesystem on this system" >&2;
  echo "Abort: $mkfsCommand does not exist" >&2;
  exit 1;
}

lvs | grep -q "$lvName"'[[:space:]]*'"$vgName" && {
  echo "Abort: Logical volume $lvName already exists in vg $vgName" >&2;
  exit 1;
}

[ -e "$mountFrom" ] && {
  echo "Abort: device exists $mountFrom" >&2;
  exit 1;
}

echo "All checks passed!!! Provisioning new LVM using:";
echo "  Device: $device";
echo "  Device Partition: $devicePartition";
echo "  Volume Group: $vgName";
echo "  Logical Volume: $lvName";
echo "  FS Type: $fsType";
echo "  Mount: $mountFrom -> $mountTo";
echo ;
echo ;

echo "Writing new Linux LVM (8e) partition to $device";
(
echo o # Create a new empty DOS partition table
echo n # Add a new partition
echo p # Primary partition
echo 1 # Partition number
echo   # First sector (Accept default: 2048)
echo   # Last sector (Accept default: varies)
echo t # Change partition type (default is Linux 83)
echo 8e # Specify Linux LVM (8e) as partition type
echo w # Write changes
echo p # Show partition table
) | fdisk "$device";
echo ;

echo 'Creating new LVM PV...';
pvcreate "$devicePartition";
pvdisplay;
echo ;

echo "Creating volume group $vgName on PV $devicePartition";
vgcreate "$vgName" "$devicePartition";
vgdisplay;
echo ;

echo "Creating new logical volume $lvName in group $vgName on PV $devicePartition";
lvcreate -n "$lvName" -l 100%FREE "$vgName";
lvdisplay "$vgName";
echo ;

echo "Creating filesystem on LV $lvName";
"$mkfsCommand" "$mountFrom";
blkid | grep "$lvName\|$device";
echo ;

echo "Adding to fstab...";
sed -i "\#$mountFrom#d" /etc/fstab;
echo "$mountFrom $mountTo $fsType defaults 0 0" >> /etc/fstab;
mkdir -p "$mountTo";
cat /etc/fstab;
echo ;

echo "Mounting for the first time to $mountTo";
mount "$mountFrom";
echo ;

echo 'Complete, new disk is available for use!';
