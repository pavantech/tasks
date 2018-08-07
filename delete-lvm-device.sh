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


echo "All checks passed!!! Provisioning new LVM using:";
echo "  Device: $device";
echo "  Device Partition: $devicePartition";
echo "  Volume Group: $vgName";
echo "  Logical Volume: $lvName";
echo "  FS Type: $fsType";
echo "  Mount: $mountFrom -> $mountTo";
echo ;
echo ;


echo "Umount to $mountTo";
umount "$mountFrom";
echo ;

echo "Removing form fstab...";
sed -i "\#$mountFrom#d" /etc/fstab;
cat /etc/fstab;
echo ;

echo "Removing logical volume $lvName in group $vgName on PV $devicePartition";
lvremove $mountFrom
lvdisplay "$vgName";
echo ;

echo "Removing volume group $lvName on PV $devicePartition";
vgremove "$lvName";
vgdisplay;
echo ;

echo 'Removie LVM PV...';
pvremove "$devicePartition";
pvdisplay;
echo ;

echo "Removing partition device partition to $device";
(
echo d # Removing the lvm device
echo w # Write changes
) | fdisk "$device";
echo ;

echo 'Complete, Disk removed successfully !';
