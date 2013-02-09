.. XXX: reference/datamodel and this have quite a few overlaps!


.. _installation:

**************
Installation
**************

It's easy, you need to install **samba** and **whois** for command `mkpasswd`.

::

    apt-get install samba samba-common-bin whois


You need also to install **whiptail** l >= 0.52.10-8 or **dialog**::

    apt-get install whiptail
or::

    apt-get install dialog

.. note::

    I recommend you to use **whiptail**.


Last point the script need a filesystem with **ACL** enable. To install ACL :

Install the acl package : ::

    apt-get install acl

Add **acl** option in your **/etc/fstab** file to enable this option at the next reboot : ::

    /dev/sda2 /home ext4    defaults,acl   0   2

.. note::

    If your partition is already mounted and you don't wand to reboot now, you can execute the next command to remount
    the partition with acl option.

    ``mount -o remount,acl /home``

