#!/bin/bash

# Color Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Cyan='\033[0;36m'         # Cyan

# PHP Version
PHP_VERSION="$1"

# PHP Modules folder
MODULES=$(php$PHP_VERSION -i | grep extension_dir | grep php | awk '{print $NF}')

# System Architecture
ARCH=$(getconf LONG_BIT)

getFiles() {
  cd /tmp
  if [ ! -f ioncube_loaders_lin_x86-64.tar.gz ]; then
	  # if machine type is 64-bit, download and extract 64-bit files
	  if [ $ARCH == 64 ]; then
	    echo -e "${Cyan} \n Downloading.. ${Color_Off}"
	    wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz

	    echo -e "${Cyan} Extracting files.. ${Color_Off}"
	    tar xvfz ioncube_loaders_lin_x86-64.tar.gz

	  # else, get 32-bit files
	  else
	    echo -e "${Cyan} \n Downloading.. ${Color_Off}"
	    wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86.tar.gz

	    echo -e "${Cyan} Extracting files.. ${Color_Off}"
	    tar xvfz ioncube_loaders_lin_x86.tar.gz
	  fi
  fi

  echo -e "${Cyan} \n Copying files to PHP Modules folder.. ${Color_Off}"
  # Copy files to modules folder
  sudo cp "ioncube/ioncube_loader_lin_${PHP_VERSION}.so" $MODULES
  sudo cp "ioncube/ioncube_loader_lin_${PHP_VERSION}_ts.so" $MODULES
}

success() {
  echo -e "${Green} \n IonCube for php${PHP_VERSION} has been installed. ${Color_Off}"
}

# RUN
getFiles
success
