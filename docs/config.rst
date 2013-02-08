.. XXX: reference/datamodel and this have quite a few overlaps!


.. _config:

**************
Configuration
**************

Configuration du script

Quelques Configuration sont possible dans ce script. Le changement çe fait dans l'entête du script en modifiant des valeurs dans des variables.

Choix de l'interface à utiliser :

 DIALOG="whiptail" 

ou

 DIALOG="dialog" 

Paramétre passé à samba aprés chaques modification de sa configuration

 SMBOPTION="restart" 

ou

 SMBOPTION="reload" 

Emplacement où sera crée les partages samba

 ALL_SHARES_PATH="/home/Samba/Shares" 

Emplacement du fichier de log du script smbtool.sh :

 LOGPATH="/tmp/smbtool" 

Propriétaire et groupe de chaques partage samba :

 SHARE_OWNERS="root:root" 



.. note::

    Si vous avez votre partition déjè montée et que vous ne voulez pas rebooter pour avoir l'option acl vous pouvez faire :

    ``mount -o remount,acl /home``

