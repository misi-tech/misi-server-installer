#!/bin/bash

#	
#	Installing Personal Media Server in ubuntu 14.04
#	Created by Eran Caballero on 11/07/2017.	
#	GNU GENERAL PUBLIC LICENSE
#	MISI TECH INC 

clear


misi_log()
{
	echo ""
	NOW=$(date)
	MISI_SEP="+----------------------------------------------------------------------"
	echo $MISI_SEP
	echo " | Misi:				$NOW"
	echo $MISI_SEP
	echo " | "$1
	echo $MISI_SEP
	echo ""
}

misi_intro()
{
	MISI_SERVER_NAME="Misi Personal Media Server"
	misi_log "Hey :)"
	misi_log "Installing $MISI_SERVER_NAME"
}

misi_update_os()
{
	misi_log "Updating OS (Linux)..."
	apt-get -qq update
	apt-get -qq install pydf zip unzip htop
	apt-get -qq -y upgrade
	misi_log "OS updated :)"
}

misi_update_locale()
{
	sudo locale-gen "he_IL.UTF-8"|
	locale-gen "en_US.UTF-8"|
	update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
	timedatectl set-timezone Etc/UTC
        misi_log "Locale (UTF+TZ) updated"
}

misi_handle_sudoers()
{
        misi_log "Handling Sudoers"
	dpkg-statoverride --update --add root sudo 4750 /bin/su
}

misi_update_profiles()
{
	if grep -r "MISI :]" "/etc/profile";
	then 
		misi_log "Profile file already updated"
	else
		echo "# MISI :]" >> /etc/profile
		echo "LD_LIBRARY_PATH=/usr/local/lib/" >> /etc/profile
		echo "PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/" >> /etc/profile
		echo "" >> /etc/profile
		echo "JAVA_HOME=/usr/lib/jvm/java-8-oracle" >> /etc/profile
		echo "JRE_HOME=/usr/lib/jvm/java-8-oracle/jre/bin/java" >> /etc/profile
		echo "PATH=$PATH:$HOME/bin:JAVA_HOME:JRE_HOME" >> /etc/profile
		source /etc/profile
		misi_log "Profile file updated"
	fi
}

misi_ssh_setup()
{
	SSHD_CONFIG_FILE="/etc/ssh/sshd_config"
	misi_log "Reconfigure password authentication"
	sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' $SSHD_CONFIG_FILE
	service ssh restart
	misi_log "Done..."
}

misi_reboot_message_setup()
{
        MISI_OS_REBOOT_MESSAGE_FILE="/usr/lib/update-notifier/update-motd-reboot-required"
        if grep -r "MISI :]" $MISI_OS_REBOOT_MESSAGE_FILE;
        then 
                misi_log "reboot message already setup"
        else
                MISI_OS_REBOOT_MESSAGE_FILE_CONTENT="#\r\n# helper for update-motd\r\nif [ -f /var/run/reboot-required ]; then\r\n\tcat /var/run/reboot-required\r\n\t# MISI :]\r\n\techo 'Packages causing reboot:'\r\n\tcat /var/run/reboot-required.pkgs\r\nfi"
                echo -e $MISI_OS_REBOOT_MESSAGE_FILE_CONTENT > $MISI_OS_REBOOT_MESSAGE_FILE
                misi_log "Reboot message setup OK"
        fi
}

misi_web_install()
{
	#Java + Apache + PHP
	misi_log "Installing Java..."
	MISI_APACHE_CONF_FILE="/etc/apache2/apache2.conf"
	MISI_REQUIERED_APACHE_INSTALLATION="apache2 apache2-doc apache2-utils libapache2-mod-php7.0 apache2-dev0"
	add-apt-repository ppa:webupd8team/java
	apt-get -qq update
	#Installing JAVA
	apt-get -qq -y install oracle-java8-installer
	update-java-alternatives -s java-8-oracle
	misi_log "Installing Misi Web Server..."
	apt-get clean
	add-apt-repository ppa:ondrej/apache2
	apt-get -qq update
	apt-get -qq -y install $MISI_REQUIERED_APACHE_INSTALLATION
	cp $MISI_APACHE_CONF_FILE $MISI_APACHE_CONF_FILE.bak
	#ADD sed of ServerName localhost
	sudo sed -i 's/LogLevel */LogLevel 'info'/' $MISI_APACHE_CONF_FILE
	source /etc/apache2/envvars
	service apache2 restart
	#Installing PHP 7.0
	MISI_REQUIERED_PHP_INSTALLATION="php7.0 php7.0-mcrypt php7.0-mbstring php7.0-curl php7.0-cli php7.0-mysql 
		php7.0-gd php7.0-intl php7.0-xs php-xdebug php-apcu php7.0-fpm"
	apt-get -qq -y install python-software-properties
	add-apt-repository ppa:ondrej/php
	apt-get -qq update
	apt-get -qq -y install $MISI_REQUIERED_PHP_INSTALLATION
}

misi_cdn_server_install()
{
	misi_log "Installing Misi-CDN server"
	./misi-cdn-server-install.sh
	misi_log "Misi-CDN server installed"
}

misi_update_apache_conf_mod()
{
		MISI_APACHE_CONF_FILE="/etc/apache2/apache2.conf"
		if grep -r "MISI :]" $MISI_APACHE_CONF_FILE;
        then 
                misi_log "Adding mp4 module"
        else
                MISI_APACHE_CONF_FILE_CONTENT_1="LoadModule h264_streaming_module /usr/lib/apache2/modules/mod_h264_streaming.so"
                MISI_APACHE_CONF_FILE_CONTENT_2="AddHandler h264-streaming.extensions .mp4"
                echo "# MISI :]" >> $MISI_APACHE_CONF_FILE
                echo -e $MISI_APACHE_CONF_FILE_CONTENT1 >> $MISI_APACHE_CONF_FILE
                echo -e $MISI_APACHE_CONF_FILE_CONTENT2 >> $MISI_APACHE_CONF_FILE
                misi_log "Apache mod message setup OK"
        fi
}

misi_mod_web_server()
{
	misi_log "Updating web server"
	MISI_APACHE_CONF_FILE="/etc/apache2/apache2.conf"
	MISI_APACHE_MOD_FILE="apache_mod_h264_streaming-2.2.7.tar.gz"
	MISI="/var/Misi"
	MISI_SOURCE_FOLDER="$MISI/CDN/source/apache-mp4-mod"
	mkdir -p $MISI_SOURCE_FOLDER
	wget http://h264.code-shop.com/download/$MISI_APACHE_MOD_FILE
	mv $MISI_APACHE_MOD_FILE $MISI_SOURCE_FOLDER
	tar -xvf $MISI_SOURCE_FOLDER/$MISI_APACHE_MOD_FILE -C $MISI_SOURCE_FOLDER
	cd $MISI_SOURCE_FOLDER/mod_h264_streaming-2.2.7
	#$MISI_SOURCE_FOLDER/configure --with-apxs=`which apxs2`
	./configure --with-apxs=`which apxs2`
	#$MISI_SOURCE_FOLDER/make
	make
	#$MISI_SOURCE_FOLDER/make install
	make install
    cd -
    rm -rf $MISI_SOURCE_FOLDER
    misi_update_apache_conf_mod    


	# update php
	a2query -m php7.0
	a2enmod php7.0

	service apache2 restart
	misi_log "Web server installed.."
}

misi_ffmpeg_installation()
{
	misi_log "Installing FFMpeg"
	add-apt-repository ppa:mc3man/trusty-media
	apt-get -qq update
	apt-get -y install ffmpeg
	misi_log "FFMpeg installed :)"
}

misi_opencv_installation()
{
	MISI_OPENCV_REQUIERED_INSTALLATION="libopencv-dev build-essential checkinstall cmake pkg-config yasm libjpeg-dev 
		libjasper-dev libavcodec-dev libavformat-dev libswscale-dev libdc1394-22-dev libxine-dev libgstreamer0.10-dev 
		libgstreamer-plugins-base0.10-dev libv4l-dev python-dev python-numpy python-tk python3-dev python3-tk python3-numpy 
		libtbb-dev libeigen3-dev libqt4-dev libgtk2.0-dev libfaac-dev libmp3lame-dev libopencore-amrnb-dev git
		libopencore-amrwb-dev libtheora-dev libvorbis-dev libxvidcore-dev x264 v4l-utils qt5-default libvtk6-dev ant 
		default-jdk zlib1g-dev libwebp-dev libpng12-dev libtiff5-dev libopenexr-dev libgdal-dev libx264-dev libtiff4-dev 
		libtbb2 libglew-dev libatlas-base-dev libgtk-3-dev libatlas-base-dev gfortran libglew-dev doxygen libpolarssl-dev 
		libnl-utils"
	apt-get -qq -y install $MISI_OPENCV_REQUIERED_INSTALLATION
	apt-get -qq -y install libgstreamer*
	misi_log "Compiling and installing OpenCV"
	  typeset src_dir=/var/opencv
	  typeset opencv_ver="3.2.0"
	  typeset opencv_link="https://github.com/Itseez/opencv/archive/${opencv_ver}.zip"
	  	mkdir -p ${src_dir}
	    cd ${src_dir}
	    wget ${opencv_link}
	    cd opencv-${opencv_ver}
	    cd /usr/include/linux
	    ln -s ../libv4l1-videodev.h videodev.h
	    cd -
	    mkdir -p build
	    cd build
	    cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local -D WITH_TBB=ON 
	    	  -D BUILD_NEW_PYTHON_SUPPORT=ON -D WITH_V4L=ON -D WITH_QT=ON -D WITH_OPENGL=ON 
	    	  -D WITH_FFMPEG=ON -D_FORCE_INLINES -D WITH_IPP=ON -DWITH_CUDA=OFF ..
	    make -j4
	    checkinstall
	    /bin/bash -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf'
	    ldconfig
	    make install
	  misi_log "Creating link to libippicv.a"
	  	sudo cp /var/opencv/opencv-3.2.0/build/3rdparty/ippicv/ippicv_lnx/lib/intel64/libippicv.a /usr/local/lib/
	  misi_log "Updating ld libs"
	  	sh -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf'
	  ldconfig
	  misi_log "Creating link from /dev/null to /dev/raw1394"
	  	ln /dev/null /dev/raw1394
	  	ldconfig -v
	    updatedb && locate libopencv_core.so.${opencv_ver}
	  misi_log "Version Of OpenCV installation"
	    pkg-config --modversion opencv
	  misi_log "OpenCV setup updated :)"
}



# MISI MAIN FLOW

misi_intro
misi_update_os
misi_update_locale
misi_handle_sudoers
misi_update_profiles
misi_ssh_setup
misi_update_profiles
misi_reboot_message_setup
misi_web_install
misi_cdn_server_install
misi_mod_web_server
misi_ffmpeg_installation
misi_opencv_installation
