.. XXX: reference/datamodel and this have quite a few overlaps!


.. _installation:

**************
Installation
**************

C'est simple, il vous faut simplement un serveur **samba** classique installé et de **whois** pour la commande mkpasswd.

::

    apt-get install samba samba-common-bin whois


Vous aurez aussi besoin de **whiptail** l >= 0.52.10-8 ou **dialog**::

    apt-get install whiptail
ou::

    apt-get install dialog

.. note::

    Vous pouvez aussi bien utiliser dialog que whiptail mais je vous recommande **whiptail**.


Dernier point il faudra que votre systéme supporte les **ACL**. Pour les installer c'est simple : 

On install le paquet : ::

    apt-get install acl

On ajoute l'option **acl** à la partition qui contiendra vos partages dans **/etc/fstab** : ::

    /dev/sda2 /home ext4    defaults,acl   0   2

.. note::

    Si vous avez votre partition déjè montée et que vous ne voulez pas rebooter pour avoir l'option acl vous pouvez faire :

    ``mount -o remount,acl /home``

