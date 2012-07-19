#!/bin/sh

cat > /target/root/post.sh << EOF
#!/bin/bash
mv /etc/grub.d/20_linux_xen /etc/grub.d/09_linux_xen
echo "GRUB_CMDLINE_XEN=\"dom0_mem=2G,max:2G\""
/usr/sbin/update-grub2
sed -i "s/\\\$XEND status && return 1/return 0/" /etc/init.d/xend
EOF

cat > /target/etc/rc.local <<EOF
#!/bin/bash

POOL=\$(xe pool-list --minimal)
DEFAULTSR=\$(xe pool-param-get uuid=\${POOL} \
    param-name=default-SR)

# Quit if we already have default SR
[ "<not in database>" = "\${DEFAULTSR}" ] || exit 0

SRSIZE='200GiB'
SRDEV='/dev/sda7'

. /etc/xcp/inventory

SR=\$(xe sr-create host-uuid=\${INSTALLATION_UUID} \
    type=ext name-label='Local storage' \
    physical-size=\${SRSIZE} device-config:device=\${SRDEV})
xe pool-param-set uuid=\${POOL} default-SR=\${SR}
EOF

echo "TOOLSTACK=xapi" > /target/etc/default/xen
echo "bridge" > /target/etc/xcp/network.conf

chmod +x /target/root/post.sh
chroot /target /root/post.sh

ln -s qemu-linaro /target/usr/share/qemu
