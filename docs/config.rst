.. XXX: reference/datamodel and this have quite a few overlaps!


.. _config:

**************
Configuration
**************

Configuration du script smbtool

La configuration du script se fait l'entête en modifiant des valeurs dans des variables.

Choix de l'interface "graphique" à utiliser :

.. code-block:: bash

    DIALOG="whiptail" 

ou

.. code-block:: bash

    DIALOG="dialog" 

lors du changement de configuration vous avez le choix de faire un restart ou un simple reload samba :

.. code-block:: bash

    SMBOPTION="restart" 

ou

.. code-block:: bash

    SMBOPTION="reload" 

Choix de l'emplacement où sera crée les partages :

.. code-block:: bash

    ALL_SHARES_PATH="/home/Samba/Shares" 

Emplacement du fichier de log :

.. code-block:: bash

    LOGPATH="/tmp/smbtool" 

Propriétaire et groupe systéme des partages samba :

.. code-block:: bash

    SHARE_OWNERS="root:root" 

.. note::

    l'utilisateur doit être différent de celui qui va accéder aux partages. Ce sont les acl qui vont donner les droits d'accès
    et non les droits systéme.

