rootpw --plaintext root
firstboot --disable
timezone America/New_York --utc
keyboard --vckeymap=us --xlayouts='us'
lang en_US.UTF-8
reboot
text
skipx

ignoredisk --only-use=vda
clearpart --all --initlabel --disklabel=gpt --drives=vda
part /boot/efi --size=512 --fstype=efi
part /boot --size=512 --fstype=xfs --label=boot
part / --fstype="xfs" --ondisk=vda --encrypted --label=root --luks-version=luks2 --grow --passphrase MY-LUKS-PASSPHRASE

%packages
@^server-product-environment
%end

%post
# Set the secret path as a crypttab keyfile
# Append `keyfile-erase` option to unlink it after unlock
cat /etc/crypttab | awk '{print $1" "$2" /sys/kernel/security/secrets/coco/736869e5-84f0-4973-92ec-06879ce3da0b "$4",keyfile-erase"}' | tee /etc/crypttab
# Put `efi_secret` driver in the initrd
echo 'add_drivers+=" efi_secret "' > /etc/dracut.conf.d/99-efi_secret.conf
# Trigger initrd rebuild
dnf reinstall -y kernel\*
%end
