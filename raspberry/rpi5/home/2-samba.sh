#! /bin/sh

sudo apt install samba samba-common-bin -y

sudo mkdir -p /mnt/data/shared
sudo chmod 777 -R /mnt/data/shared

if ! grep -q '\[shared\]' /etc/samba/smb.conf ; then
    {
    echo '[shared]'
    echo 'path = /mnt/data/shared'
    echo 'writeable=Yes'
    echo 'create mask=0666'
    echo 'directory mask=0777'
    echo 'public=Yes'
    } >> /etc/samba/smb.conf

    sudo systemctl restart smbd
    echo '/etc/samba/smb.conf'
fi

echo 'done'