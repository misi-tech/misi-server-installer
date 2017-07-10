#!/bin/bash
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
	MISI_SERVER_NAME="Misi CDN Server"
	misi_log "Hey :)"
	misi_log "Installing $MISI_SERVER_NAME"
}

misi_update_os()
{
	misi_log "Updating OS (Linux)..."
	MISI_REQUIERED_INSTALLATION="pydf zip unzip htop mesa-utils apache2 apache2-doc apache2-utils libapache2-mod-php7.0 apache2-dev php7.0-mcrypt php7.0-mbstring php7.0-curl php7.0-gd php7.0-intl php7.0-xs php-xdebug php-apcu ffmpeg ffmpeg-doc alsa-base libportaudio2 libglew-dev libgstreamer* doc-base libsigc++-2.0-doc libuuid-perl libxml++2.6-doc doxygen libmbedtls-dev libnl-utils freeglut3-dev default-jdk default-jdk-headless default-jre default-jre-headless default-java-plugin"
	apt-get -qq update 
	apt-get -qq install $MISI_REQUIERED_INSTALLATION
	apt-get -qq -y upgrade
	misi_log "OS updated :)"
}

misi_update_locale()
{
	sudo locale-gen "he_IL.UTF-8"|
	locale-gen "en_US.UTF-8"|
	update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
	timedatectl set-timezone Etc/UTC
        misi_log "Locale (UTF+TZ) updated "
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
	misi_log "Reconfigure password authentication"
	sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
	service ssh restart
	misi_log "Done..."
}

misi_reboot_message_setup()
{
        MISI_OS_REBOOT_MESSAGE_FILE="/usr/lib/update-notifier/update-motd-reboot-required"
        if grep -r "MISI :]" $MISI_OS_REBOOT_MESSAGE_FILE;
        then 
                misi_log "Reboot message already setup"
        else
                MISI_OS_REBOOT_MESSAGE_FILE_CONTENT="#\r\n# helper for update-motd\r\nif [ -f /var/run/reboot-required ]; then\r\n\tcat /var/run/reboot-required\r\n\t# MISI :]\r\n\techo 'Packages causing reboot:'\r\n\tcat /var/run/reboot-required.pkgs\r\nfi"
                echo -e $MISI_OS_REBOOT_MESSAGE_FILE_CONTENT > $MISI_OS_REBOOT_MESSAGE_FILE
                misi_log "Reboot message setup OK"
        fi
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

misi_update_web_server()
{
	misi_log "Updating web server"
	# update apache
	chmod 775 -R /var/www
	cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.orig

	MISI_APACHE_CONF_FILE="/etc/apache2/apache2.conf"
	MISI_APACHE_MOD_FILE="apache_mod_h264_streaming-2.2.7.tar.gz"
	MISI_SOURCE_FOLDER="/var/Misi/CDN/source/apache-mp4-mod"
	#MISI-TO-DO: change /var/misi to $misi
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
}


misi_opencv_setup()
{
	MISI_OPENCV_REQUIERED_INSTALLATION="build-essential checkinstall cmake pkg-config yasm libjpeg-dev libjasper-dev libavcodec-dev libavformat-dev libswscale-dev libdc1394-22-dev libxine2 libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev libv4l-dev python-dev python-numpy libtbb-dev libqt4-dev libgtk2.0-dev libmp3lame-dev libopencore-amrnb-dev libopencore-amrwb-dev libtheora-dev libvorbis-dev libxvidcore-dev x264 v4l-utils"
	apt-get -qq install $MISI_OPENCV_REQUIERED_INSTALLATION
	
	sudo ldconfig -v
	sudo updatedb && locate libopencv_core.so.2.4.9
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
misi_update_web_server
misi_opencv_setup
