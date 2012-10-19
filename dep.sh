#!/bin/bash
redhat_pkgs=(gcc-c++ mysql-devel python-devel libevent-devel)
debian_pkgs=(g++ libmysqlclient-dev python-dev libevent-dev)
DEPENDENCIES=(git python-setuptools python-virtualenv python-pip)

# Check if user is root 
if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root" 2>&1
	exit 1
fi

# Detect package manager and set command to check package
if which dpkg &> /dev/null; then
	cmd='dpkg -l | grep -w "ii %s"'
	DEPENDENCIES=(${DEPENDENCIES[*]} ${debian_pkgs[*]})
elif which rpm &> /dev/null; then
	cmd="rpm --quiet -q %s"
	DEPENDENCIES=(${DEPENDENCIES[*]} ${redhat_pkgs[*]})
else
	echo "ERROR: failed to detect package manager"
	exit 1
fi

# Check if required packages are installed
PKGSTOINSTALL=""
for (( i=0; i<${tLen=${#DEPENDENCIES[@]}}; i++ )); do
	printf -v run "$cmd" ${DEPENDENCIES[$i]} 
	$run
	if [[ $? != 0 ]]; then
		PKGSTOINSTALL=$PKGSTOINSTALL" "${DEPENDENCIES[$i]}
	fi	
done

# If some dependencies are missing, asks if user wants to install
if [ "$PKGSTOINSTALL" != "" ]; then
	echo -n "Some dependencies are missing. Want to install them? (Y/n): "
	read SURE
	# If user want to install missing dependencies
	if [[ $SURE = "Y" || $SURE = "y" || $SURE = "" ]]; then
		NOPKGMANAGER=FALSE
		# Debian, Ubuntu and derivatives (with apt-get)
		if which apt-get &> /dev/null; then
			sudo apt-get install $PKGSTOINSTALL
		# Fedora and CentOS (with yum)
		elif which yum &> /dev/null; then
			sudo yum install -y $PKGSTOINSTALL
		# Else, if no package manager has been founded
		else
			NOPKGMANAGER=TRUE
			echo "ERROR: impossible to found a package manager in your sistem."
		fi
		# Check if installation is successful
		if [[ $? -eq 0 && ! -z $NOPKGMANAGER ]] ; then
			echo "All dependencies are satisfied."
		# Else, if installation isn't successful
		else
			echo "ERROR: impossible to install some missing dependencies. Please, install manually ${PKGSTOINSTALL[*]}."
		fi
	# Else, if user don't want to install missing dependencies
	else
		echo "WARNING: Some dependencies may be missing. So, please, install manually ${PKGSTOINSTALL[*]}."
	fi
else
	echo "All dependencies are satisfied."
fi
