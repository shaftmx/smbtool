.. XXX: reference/datamodel and this have quite a few overlaps!


.. _config:

**************
Configuration
**************

**Configure the script :**

You can edit the script and change some value if you want to customize the behavior.

**Change the graphical interface :**

.. code-block:: bash

    DIALOG="whiptail" 

or

.. code-block:: bash

    DIALOG="dialog" 

**Restart or reload the samba server when you change the configuration :**

.. code-block:: bash

    SMBOPTION="restart" 

or

.. code-block:: bash

    SMBOPTION="reload" 

**Change the location of the samba shares :**

.. code-block:: bash

    ALL_SHARES_PATH="/home/Samba/Shares" 

**Change the location of the smbtool log tile :**

.. code-block:: bash

    LOGPATH="/tmp/smbtool" 

**System owner of all samba shares :**

.. code-block:: bash

    SHARE_OWNERS="root:root" 

.. note::
    The user must be different from your samba users who have access to the shares.
    The **acl** give the access right and not the unix permission.

