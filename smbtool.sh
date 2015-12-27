#!/bin/bash

# Author: Gaël Lambert (gaelL) <gael.lambert@netwiki.fr>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Presrequis
#	- whiptail >= 0.52.10-8
#		OR
#	- dialog
#
#	- samba-common-bin  (For smbpasswd)	

##########   REQUIS   ##########
# - ACL install
# /dev/sda2 /home ext4    defaults,acl   0   2
# 
# mount -o remount,acl /home

# Interface à utiliser
# Version whiptail >= 0.52.10-8
DIALOG="whiptail --clear"
#DIALOG="dialog"

# Paramétre passé à samba
SMBOPTION="restart"
#SMBOPTION="reload" 

# Emplacement des partages samba
ALL_SHARES_PATH="/home/Samba/Shares"

# emplacement du fichier de log
LOGPATH="/tmp/smbtool"

# Propriétaire et groupe des partage
SHARE_OWNERS="root:root"

# ID mini des utilisateurs et groups à gerer 
MIN_ID_USER="1000"

#Use in /etc/init.d/$SAMBA_NAME
SAMBA_NAME="samba"

SCROLLTEXT="--scrolltext"
if [ "$DIALOG" = "dialog" ]; then 
	IS_SETUP=`which dialog`
	if [ -z "$IS_SETUP" ]; then
		echo "$(date) ... ERREUR $DIALOG not foud"
		exit 1;
	fi
	SCROLLTEXT=""
fi


#	Samba smbpasswd is setup ? 
IS_SETUP=`which smbpasswd`
if [ -z "$IS_SETUP" ]; then
	echo "$(date) ... ERREUR smbpasswd not foud (samba-common-bin)"
	exit 1;
fi

#	setfacl is setup ?
IS_SETUP=`which setfacl`
if [ -z "$IS_SETUP" ]; then
	echo "$(date) ... ERREUR setfacl not foud"
	exit 1;
fi

#	mkpasswd is setup ?
IS_SETUP=`which mkpasswd`
if [ -z "$IS_SETUP" ]; then
	echo "$(date) ... ERREUR mkpasswd not foud (whois)"
	exit 1;
fi


#
#	Check des param
#
do_checkParam()
{
	case "$CHOIX" in
		"add-user") do_adduser ;;
		"del-user") do_deluser ;;
		"user-passwd") do_userpasswd ;;
		"add-group") do_addgroup ;;
		"del-group") do_delgroup ;;
		"add-usertogroup") do_addUserToGroup ;;
		"modif-usergroup") do_modifUserGroup ;;
		"add-share") do_addshare ;;
		"mod-share") do_modshare ;;
		"del-share") do_delshare ;;
		"en-share") do_enshare ;;
		"dis-share") do_disshare ;;
		"list-user") do_listUser ;;
		"list-group") do_listGroup ;;
		"list-share") do_listShare ;;
		*)
			rm $TMPFILE
			exit 0
		;;
	esac

	return 0
}



###################################
#		USER
###################################

#
#	adduser --add-user
#
do_adduser()
{
	#:>$TMPFILE  #	clear
#useradd --gid "www-data" --create-home --comment "$user_fullname" --password  $(mkpasswd $user_password) "$user_logname"

	$DIALOG --title "Add User" --inputbox "User name :" 22 60 2>$TMPFILE
	USER=`cat $TMPFILE`

	if [ -n "$USER" ];then
	
		$DIALOG --title "Add User" --passwordbox "User password :" 22 60 2>$TMPFILE
		PASSWORD=`cat $TMPFILE`
	
		useradd --no-user-group -g "AllUsers" --password $(mkpasswd "$PASSWORD") "$USER" && \
smbpasswd -sa "$USER"<<EOF
$PASSWORD
$PASSWORD
EOF

		if [ "$?" = "0" ];then
			$DIALOG --title "Add User" --msgbox "Add user success" 22 60
			echo "$(date) ... Add user $USER" >>$LOGPATH # LOG
		else
			$DIALOG --title "Add User" --msgbox "Add user error" 22 60
			echo "$(date) ... Add user $USER ERROR" >>$LOGPATH # LOG
		fi
	fi

	return 0
}

#
#	deluser --del-user
#
do_deluser()
{
	#:>$TMPFILE  #	clear

	LISTUSER=`awk 'BEGIN{FS=":"; ORS=" "} { if($3>='$MIN_ID_USER' && $3<65534)  print $1" "$3" off"}' /etc/passwd`
	if [ -z "$LISTUSER" ]; then return 0; fi # Pas d'utilisateurs crée
	
	$DIALOG --title "Delete User" --checklist "Suppression d'utilisateur : " 22 60 10 $LISTUSER 2>$TMPFILE
	USER=`cat $TMPFILE`

	# Si on a des user a supprimer
	if [ -n "$USER" ];then

		# Confirm
		$DIALOG --title "Delete User" --yesno "Supprimer ces utilisateurs :$(echo -e '\t '$USER | sed 's/ /\n\t/g')" 22 60
		if [ "$?" != "0" ];then # NON
			return 0
		fi

		for name in $(echo $USER | sed 's/\"//g'); do # On vire les " qui font bugé userdel
		
			smbpasswd -x "$name" && userdel -f "$name"
			
			if [ "$?" != "0" ];then
				$DIALOG --title "Delete User" --msgbox "Delete user $name error" 22 60
				echo "$(date) ... Delete user $name ERROR" >>$LOGPATH # LOG
				return 1
			fi
			
			echo "$(date) ... Delete user $name" >>$LOGPATH # LOG
			
		done
		$DIALOG --title "Delete User" --msgbox "Delete user success:$(echo -e '\t '$USER | sed 's/ /\n\t/g')" 22 60
	fi

	return 0
}


#
#	list User --list-user
#
do_listUser()
{
	# Get liste
	echo -e "Liste des utilisateurs : \n" > $TMPFILE
	awk 'BEGIN{FS=":"} { if($3>='$MIN_ID_USER' && $3<65534){ print " - "$1"  ["$3"]"}}' /etc/passwd >> $TMPFILE
	
	$DIALOG --title "List User" --textbox $TMPFILE 22 60 $SCROLLTEXT
	
	return 0
}


#
#	user password 
#
do_userpasswd()
{


	LISTUSER=`awk 'BEGIN{FS=":"; ORS=" "} { if($3>='$MIN_ID_USER' && $3<65534)  print $1" \""$3"\" off"}' /etc/passwd`
	if [ -z "$LISTUSER" ]; then return 0; fi # Pas d'utilisateurs crée

	# get userliste   
	$DIALOG --title "User Password" --radiolist "Selection de l'utilisateur : " 22 60 10 $LISTUSER 2>$TMPFILE
	USER=`cat $TMPFILE`
	if [ -z "$USER" ]; then return 1; fi # On a rien selectionné
	

	
	$DIALOG --title "User Password" --passwordbox "User new password :" 22 60 2>$TMPFILE
	PASSWORD=`cat $TMPFILE`

	usermod --password  $(mkpasswd "$PASSWORD") "$USER" && \
smbpasswd -sa "$USER"<<EOF
$PASSWORD
$PASSWORD
EOF

	if [ "$?" = "0" ];then
		$DIALOG --title "User Password" --msgbox "Password change success" 22 60
		echo "$(date) ... User $USER password change" >>$LOGPATH # LOG
	else
		$DIALOG --title "User Password" --msgbox "Password change error" 22 60
		echo "$(date) ... User $USER password change ERROR" >>$LOGPATH # LOG
	fi

	return 0
}

###################################
#		ADD USER TO GROUP
###################################

#
#	addUserToGroup --add-usertogroup
#
do_addUserToGroup()
{

	LISTUSER=`awk 'BEGIN{FS=":"; ORS=" "} { if($3>='$MIN_ID_USER' && $3<65534)  print $1" "$3" off"}' /etc/passwd`
	if [ -z "$LISTUSER" ]; then return 0; fi # Pas d'utilisateurs crée
	
	# get userliste
	$DIALOG --title "Add User to Group" --checklist "Selection d'utilisateur : " 22 60 10 $LISTUSER 2>$TMPFILE
	USER=`cat $TMPFILE`
	if [ -z "$USER" ]; then return 1; fi # On a rien selectionné


	LISTGROUP=`awk 'BEGIN{FS=":"; ORS=" "} { if($3>513 && $3<65534)  print $1" "$1" off"}' /etc/group`
	if [ -z "$LISTGROUP" ]; then return 0; fi # Pas d'utilisateurs crée
	
	# get groupliste
	$DIALOG --title "Add User to Group" --checklist "Selection de groupes :" 22 60 10 $LISTGROUP 2>$TMPFILE
	GROUP=`cat $TMPFILE`
	if [ -z "$GROUP" ]; then return 1; fi # On a rien selectionné
	allgroup=$(echo $GROUP | sed 's/\"//g;s/ /,/g')  # mise en forme de la liste des groups

	# add user to groups
	for name in $(echo $USER | sed 's/\"//g'); do # On vire les " qui font bugé userdel
	
		usermod -a -G "$allgroup" "$name"
				
		if [ "$?" != "0" ];then
			$DIALOG --title "Add User to Group" --msgbox "Add user $name to group $allgroup error" 22 60
			echo "$(date) ... Add user $name to group $allgroup ERROR" >>$LOGPATH # LOG
			return 1
		fi
		
		echo "$(date) ... Add user $name to group $allgroup $name" >>$LOGPATH # LOG
		
	done
	$DIALOG --title "Add User to Group" --msgbox "Add users to group success :\nUsers: $(echo -e '\t '$USER | sed 's/ /\\n\t- /g;s/\"//g')\nTo groups :\n$(echo -e '\t- '$allgroup | sed 's/,/\\n\t- /g')" 22 60

}

#
#	do_modifUserGroup --modif-userGroup
#
do_modifUserGroup()
{

	LISTUSER=`awk 'BEGIN{FS=":"; ORS=" "} { if($3>='$MIN_ID_USER' && $3<65534)  print $1" \""$3"\" off"}' /etc/passwd`
	if [ -z "$LISTUSER" ]; then return 0; fi # Pas d'utilisateurs crée

	# get userliste   
	$DIALOG --title "Modif User Group" --radiolist "Selection de l'utilisateur : " 22 60 10 $LISTUSER 2>$TMPFILE
	USER=`cat $TMPFILE`
	if [ -z "$USER" ]; then return 1; fi # On a rien selectionné
	
	
	LISTGROUP=`awk 'BEGIN{FS=":"; ORS=" "} { if($3>513 && $3<65534){ if(/[:,]'$USER'(,|$)/){print $1" "$1" on"} else print $1" "$1" off"}}' /etc/group`
	# Modif group
	$DIALOG --nocancel --title "Modif User Group" --checklist "Selection de groupes :" 22 60 10 $LISTGROUP 2>$TMPFILE
	GROUP=`cat $TMPFILE`
	
	allgroup=$(echo $GROUP | sed 's/\"//g;s/ /,/g')  # mise en forme de la liste des groups
	
	usermod -G "$allgroup" "$USER"
		
	if [ "$?" = "0" ];then
		$DIALOG --title "Modif User Group" --msgbox "Modif users '$USER' to group success : $(echo -e '\n\t- '$allgroup | sed 's/,/\n\t- /g')" 22 60
		echo "$(date) ... Modif user $USER to group '$allgroup' success" >>$LOGPATH # LOG
	else
		$DIALOG --title "Modif User Group" --msgbox "Modif user $USER to group '$allgroup' ERROR" 22 60
		echo "$(date) ... Modif user $USER to group '$allgroup' ERROR" >>$LOGPATH # LOG
	fi

	return 0
}



###################################
#		GROUP
###################################

#
#	addgroup --add-group
#
do_addgroup()
{

	$DIALOG --title "Add Group" --inputbox "Group name :" 22 60 2>$TMPFILE
	GROUP=`cat $TMPFILE`

	if [ -n "$GROUP" ];then

		groupadd "$GROUP"

		if [ "$?" = "0" ];then
			$DIALOG --title "Add Group" --msgbox "Add group $GROUP success" 22 60
			echo "$(date) ... Add group $GROUP" >>$LOGPATH # LOG
		else
			$DIALOG --title "Add Group" --msgbox "Add group $GROUP error" 22 60
			echo "$(date) ... Add group $GROUP ERROR" >>$LOGPATH # LOG
		fi
	fi

	return 0
}

#
#	delgroup --del-group
#
do_delgroup()
{

	LISTGROUP=`awk 'BEGIN{FS=":"; ORS=" "} { if($3>513 && $3<65534)  print $1" "$1" off"}' /etc/group`
	if [ -z "$LISTGROUP" ]; then return 0; fi # Pas d'utilisateurs crée
	
	$DIALOG --title "Delete Group" --checklist "Suppression de groupe :" 22 60 10 $LISTGROUP 2>$TMPFILE
	GROUP=`cat $TMPFILE`

	# Si on a des user a supprimer
	if [ -n "$GROUP" ];then
	
		# Confirm
		$DIALOG --title "Delete Group" --yesno "Supprimer ces groups :$(echo -e '\t '$GROUP | sed 's/ /\n\t/g')" 22 60
		if [ "$?" != "0" ];then # NON
			return 0
		fi

		for name in $(echo $GROUP | sed 's/\"//g'); do # On vire les " qui font bugé userdel
		
			groupdel "$name"
					
			if [ "$?" != "0" ];then
				$DIALOG --title "Delete Group" --msgbox "Delete group $name error" 22 60
				echo "$(date) ... Delete group $name ERROR" >>$LOGPATH # LOG
				return 1
			fi
			
			echo "$(date) ... Delete group $name" >>$LOGPATH # LOG
			
		done
		$DIALOG --title "Delete Group" --msgbox "Delete group success:$(echo -e '\t '$GROUP | sed 's/ /\n\t/g')" 22 60
	fi


	return 0
}


#
#	list group list-group
#
do_listGroup()
{
	# Get liste
	echo -e "Liste des groups : \n" > $TMPFILE
	awk 'BEGIN{FS=":"} { if($3>513 && $3<65534){ gsub(/,/, "\n\t-", $4); print " # "$1"  ["$3"]\n\t-"$4}}' /etc/group >> $TMPFILE

	$DIALOG --title "List Group" --textbox $TMPFILE 22 60 $SCROLLTEXT
	
	
	return 0
}


###################################
#		SHARE
###################################


#
#	addshare --add-share
#
do_addshare()
{

	$DIALOG --title "Add Share" --inputbox "Share name :" 22 60 2>$TMPFILE
	SHARE=`cat $TMPFILE`


	if [ -z "$SHARE" ]; then return 0; fi # Pas de share

	# Already existe ?
	ALREADY_EXIST=`grep "### smbtool : |$SHARE| ### start ###" /etc/samba/smb.conf`
	if [ -n "$ALREADY_EXIST" ];then
		$DIALOG --title "Add Share" --msgbox "Add Share $SHARE error already exist" 22 60
		echo "$(date) ... Add Share $SHARE ERROR already exist" >>$LOGPATH # LOG
		return 1
	fi

	LISTGROUP=`awk 'BEGIN{FS=":"; ORS=" "} { if($3>513 && $3<65534)  print $1" "$1" off"}' /etc/group`
	if [ -z "$LISTGROUP" ]; then return 0; fi # Pas d'utilisateurs crée
	
	# get groupliste
	$DIALOG  --title "Add Share" --checklist "Selection de groupes :" 22 60 10 $LISTGROUP 2>$TMPFILE
	GROUP=`cat $TMPFILE`
	if [ -z "$GROUP" ]; then return 1; fi # On a rien selectionné
	allgroup=$(echo $GROUP | sed 's/\([^ ]\+\)/@\1/g;s/ /, /g')  # mise en forme de la liste des groups


cat >>/etc/samba/smb.conf<<EOF
### smbtool : |$SHARE| ### start ###
[$SHARE]
    path = $ALL_SHARES_PATH/$SHARE
	force unknown acl user = yes
	acl group control = yes
	inherit acls = yes
	inherit permissions = yes
    comment = ""
    available = yes
    guest ok = no
    browseable = yes
    writeable = yes
    public = no
    create mode = 0660
    directory mode = 2770
    inherit owner = yes
    admin users = @"root"
    valid users = $allgroup
### smbtool : |$SHARE| ### end ###
EOF


	mkdir -p "$ALL_SHARES_PATH/$SHARE"
	chown $SHARE_OWNERS "$ALL_SHARES_PATH/$SHARE"
	chmod 2775 "$ALL_SHARES_PATH/$SHARE"

	# ACL
	setfacl -R -b "$ALL_SHARES_PATH/$SHARE"
	setfacl -R -d -m o::--- "$ALL_SHARES_PATH/$SHARE"

	# add acl for group
	for name in $(echo $GROUP | sed 's/\"//g'); do # On vire les " qui font bugé userdel
	
		setfacl -R -m g:"$name":rwx "$ALL_SHARES_PATH/$SHARE"
		setfacl -R -d -m g:"$name":rwx "$ALL_SHARES_PATH/$SHARE"
			

		if [ "$?" != "0" ];then
			$DIALOG  --title "Add Share" --msgbox "Add Share $name for group $allgroup error" 22 60
			echo "$(date) ... Add Share $SHARE for group $allgroup ERROR" >>$LOGPATH # LOG
			return 1
		fi
		
		echo "$(date) ... Add Share $SHARE for group $allgroup $name" >>$LOGPATH # LOG
		
	done

	/etc/init.d/$SAMBA_NAME $SMBOPTION

	$DIALOG --title "Add Share for Group" --msgbox "Add Share *$SHARE* for group success :\nGroups :\n$(echo -e '\t-  '$allgroup | sed 's/,/\\n\t- /g')" 22 60


	return 0
}

#
#	delshare --del-share
#
do_delshare()
{

	LISTSHARE=`awk 'BEGIN{} {if(/### smbtool : (\|.+\|) ### start ###/){ split($0,a,"|"); print a[2]" "a[2]" off"}}' /etc/samba/smb.conf`
	if [ -z "$LISTSHARE" ]; then return 0; fi # Pas d'utilisateurs crée

	$DIALOG --title "Delete Share" --checklist "Suppression de partages :" 22 60 10 $LISTSHARE 2>$TMPFILE
	SHARES=`cat $TMPFILE`

	# Si on a des shares a supprimer
	if [ -z "$SHARES" ]; then return 1; fi # On a rien selectionné
	
	# Confirm
	$DIALOG --title "Delete Share" --yesno "Supprimer ces partages :$(echo -e '\t '$SHARES | sed 's/ /\n\t/g')" 22 60
	if [ "$?" != "0" ];then # NON
		return 0
	fi

	for name in $(echo $SHARES | sed 's/\"//g'); do # On vire les " qui font bugé userdel
	
		rm -R "$ALL_SHARES_PATH/$name"
		sed -i "/### smbtool : |$name| ### start ###/,/### smbtool : |$name| ### end ###/d" /etc/samba/smb.conf

		if [ "$?" != "0" ];then
			$DIALOG --title "Delete Share" --msgbox "Delete Share $name error" 22 60
			echo "$(date) ... Delete Share $name ERROR" >>$LOGPATH # LOG
			return 1
		fi
		
		echo "$(date) ... Delete Share $name" >>$LOGPATH # LOG
		
	done

	/etc/init.d/$SAMBA_NAME $SMBOPTION

	$DIALOG --title "Delete Share" --msgbox "Delete Share success:$(echo -e '\t '$SHARES | sed 's/ /\n\t/g')" 22 60


	return 0
}


#
#	list share list-share
#
do_modshare()
{

	LISTSHARE=`awk 'BEGIN{} {if(/### smbtool : (\|.+\|) ### start ###/){ split($0,a,"|"); print a[2]" "a[2]" off"}}' /etc/samba/smb.conf`
	if [ -z "$LISTSHARE" ]; then return 0; fi # Pas d'utilisateurs crée

	# get userliste   
	$DIALOG --title "Modif Share" --radiolist "Selection d'un share : " 22 60 10 $LISTSHARE 2>$TMPFILE
	SHARE=`cat $TMPFILE`
	if [ -z "$SHARE" ]; then return 1; fi # On a rien selectionné

	# Make group regex group1|group2| ...
	regexG=`awk '/^### smbtool : \|'$SHARE'\| ### start ###/,/^### smbtool : \|'$SHARE'\| ### end ###/' /etc/samba/smb.conf | awk 'BEGIN{} {if(/valid users/){gsub(/,/,"|",$0);gsub(/.*= +|@| |"/, "", $0); print $0}}'`
	LISTGROUP=`awk 'BEGIN{FS=":"; ORS=" "} { if($3>513 && $3<65534){ if(/^'$regexG':/){print $1" "$1" on"} else print $1" "$1" off"}}' /etc/group`
	# Modif group
	$DIALOG --title "Modif Share" --checklist "Selection de groupes :" 22 60 10 $LISTGROUP 2>$TMPFILE
	GROUP=`cat $TMPFILE`
	if [ -z "$GROUP" ]; then return 1; fi # On a rien selectionné
	allgroup=$(echo $GROUP | sed 's/\([^ ]\+\)/@\1/g;s/ /, /g')  # mise en forme de la liste des groups


	sed -i '/### smbtool : |'$SHARE'| ### start ###/,/### smbtool : |'$SHARE'| ### end ###/s/valid users *=.*/valid users = '$allgroup'/g' /etc/samba/smb.conf

	# ACL
	setfacl -R -b "$ALL_SHARES_PATH/$SHARE"
	setfacl -R -d -m o::--- "$ALL_SHARES_PATH/$SHARE"
		
	# add acl for group
	for name in $(echo $GROUP | sed 's/\"//g'); do # On vire les " qui font bugé userdel
	
		setfacl -R -m g:"$name":rwx "$ALL_SHARES_PATH/$SHARE"
		setfacl -R -d -m g:"$name":rwx "$ALL_SHARES_PATH/$SHARE"

		if [ "$?" != "0" ];then
			$DIALOG  --title "Modif Share" --msgbox "Modif Share $name for group $allgroup error" 22 60
			echo "$(date) ... Modif Share $name for group $allgroup ERROR" >>$LOGPATH # LOG
			return 1
		fi
		
		echo "$(date) ... Modif Share $name for group $allgroup $name" >>$LOGPATH # LOG
		
	done

	/etc/init.d/$SAMBA_NAME $SMBOPTION

	return 0
}



#
#	enable share
#
do_enshare()
{

	LISTSHARE=""
	# cherche les share disable
	tmp_LISTSHARE=`awk 'BEGIN{} {if(/### smbtool : (\|.+\|) ### start ###/){ split($0,a,"|"); print a[2]" "}}' /etc/samba/smb.conf`
	if [ -z "$tmp_LISTSHARE" ]; then return 0; fi # Pas de share crée

	for name in $tmp_LISTSHARE; do 
		isAvailable=`awk '/^### smbtool : \|'$name'\| ### start ###/,/^### smbtool : \|'$name'\| ### end ###/' /etc/samba/smb.conf | egrep 'available *= *no'`
		if [ -n "$isAvailable" ]; then LISTSHARE="$LISTSHARE $name $name off"; fi
	done

	if [ -z "$LISTSHARE" ]; then return 0; fi # Pas de share desactivé

	$DIALOG --title "Enable Share" --checklist "Activation de partages :" 22 60 10 $LISTSHARE 2>$TMPFILE
	SHARES=`cat $TMPFILE`

	if [ -z "$SHARES" ]; then return 1; fi # On a rien selectionné

	# Changement de la valeur de available pour chaques repertoires
	for name in $(echo $SHARES | sed 's/\"//g'); do # On vire les " qui font bugé userdel
		sed -i '/### smbtool : |'$name'| ### start ###/,/### smbtool : |'$name'| ### end ###/s/available *= *no/available = yes/g' /etc/samba/smb.conf

		if [ "$?" != "0" ];then
			$DIALOG --title "Enable Share" --msgbox "Enable Share $name error" 22 60
			echo "$(date) ... Enable Share $name ERROR" >>$LOGPATH # LOG
			return 1
		fi
		
		echo "$(date) ... Enable Share $name" >>$LOGPATH # LOG
	done

	/etc/init.d/$SAMBA_NAME $SMBOPTION

	return 0
}



#
#	disable share
#
do_disshare()
{
	LISTSHARE=""
	# cherche les share enable
	tmp_LISTSHARE=`awk 'BEGIN{} {if(/### smbtool : (\|.+\|) ### start ###/){ split($0,a,"|"); print a[2]" "}}' /etc/samba/smb.conf`
	if [ -z "$tmp_LISTSHARE" ]; then return 0; fi # Pas de share crée

	for name in $tmp_LISTSHARE; do 
		isAvailable=`awk '/^### smbtool : \|'$name'\| ### start ###/,/^### smbtool : \|'$name'\| ### end ###/' /etc/samba/smb.conf | egrep 'available *= *yes'`
		if [ -n "$isAvailable" ]; then LISTSHARE="$LISTSHARE $name $name off"; fi
	done

	if [ -z "$LISTSHARE" ]; then return 0; fi # Pas de share activé

	$DIALOG --title "Disable Share" --checklist "Desactivation de partages :" 22 60 10 $LISTSHARE 2>$TMPFILE
	SHARES=`cat $TMPFILE`

	if [ -z "$SHARES" ]; then return 1; fi # On a rien selectionné

	# Changement de la valeur de available pour chaques repertoires
	for name in $(echo $SHARES | sed 's/\"//g'); do # On vire les " qui font bugé userdel
		sed -i '/### smbtool : |'$name'| ### start ###/,/### smbtool : |'$name'| ### end ###/s/available *= *yes/available = no/g' /etc/samba/smb.conf

		if [ "$?" != "0" ];then
			$DIALOG --title "Disable Share" --msgbox "Disable Share $name error" 22 60
			echo "$(date) ... Disable Share $name ERROR" >>$LOGPATH # LOG
			return 1
		fi
		
		echo "$(date) ... Disable Share $name" >>$LOGPATH # LOG
	done

	/etc/init.d/$SAMBA_NAME $SMBOPTION

	return 0
}



#
#	list share list-share
#
do_listShare()
{

	# Get liste
	echo -e "Liste des partages : \n" > $TMPFILE
	#egrep -A$NB_LN_SMB_CONF '^### smbtool : \|.+\| ### start ###' /etc/samba/smb.conf | \
	awk '/^### smbtool : \|.+\| ### start ###/,/^### smbtool : \|.+\| ### end ###/' /etc/samba/smb.conf | \
	awk 'BEGIN{FS=":"} { if(/^\[.+\]/ || /available/){ print $1 }{ if(/valid users/){ gsub(/@/, "\n\t-", $1); print $1}}}' >> $TMPFILE

	$DIALOG --title "List Share" --textbox $TMPFILE 22 60 $SCROLLTEXT

	return 0
}

###################################
#		OTHER
###################################

#
#	init
#
do_init()
{
	CHECK=`getent group | grep "AllUsers:"`
	
	if [ -z "$CHECK" ]; then
		groupadd --gid 513 AllUsers
		echo "$(date) ... Add group 513 AllUsers" >>$LOGPATH # LOG
	fi

	return 0
}



###################################
#		MAIN
###################################

#
#	main menu
#
do_main()
{

	# init
	do_init
	


	TMPFILE=`mktemp`

	while true; do
		$DIALOG --title "$0" --menu "Menu smbtool :" 22 60 15 \
		"add-user" "      add user"  \
		"del-user" "      delete user"  \
		"user-passwd" "      change user password"  \
		"add-group" "      add group"  \
		"del-group" "      delete group" \
		"add-usertogroup" "      add user to group"  \
		"modif-usergroup" "      Modif user groups"  \
		"add-share" "      add share" \
		"mod-share" "      Modif share" \
		"del-share" "      delete share" \
		"en-share" "      enable share" \
		"dis-share" "      disable share" \
		"list-user" "      Liste users" \
		"list-group" "      Liste groups" \
		"list-share" "      Liste share" 2>$TMPFILE
		CHOIX=`cat $TMPFILE`

		do_checkParam # $CHOIX
	done;


	return 0
}



do_main


