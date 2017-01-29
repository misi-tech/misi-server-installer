#!/usr/bin/env bash

### Proxy definitions if required:
# export http_proxy=http://host:port
# export https_proxy=http://host:port

# Variables
PROGRAM=`echo $0 | sed 's?.*/??'`
logfile=${PROGRAM}_`date +%Y%m%d-%H%M%S`
apt_src=/etc/apt/sources.list.d
ret_true=/bin/true
run_update='no'

# Package lists
common_pkgs='
 pkg-config
 ant
 build-essential
 htop
 git
 unzip
 zip
 wget
 pydf
 oracle-java8-installer
 oracle-java8-set-default
'

mysql_pkgs='
 mysql-client-5.6
 mysql-client-core-5.6
 mysql-server-5.6
'

web_pkgs='
 apache2
 apache2-doc
 apache2-utils
 php7.0
 php7.0-mcrypt
 php7.0-mbstring
 php7.0-curl
 php7.0-cli
 php7.0-mysql
 php7.0-gd
 php7.0-intl
 php7.0-xs
 php-xdebug
 php-apcu
 php7.0-fpm
 php7.0-json
 php7.0-common
 php7.0-sqlite3
'

media_pkgs='
 doxygen
 checkinstall
 cmake
 make
 libopencv-dev
 libjpeg-dev
 libjasper-dev
 libavcodec-dev
 libavformat-dev
 libswscale-dev
 libdc1394-22-dev
 libxine-dev
 libgstreamer0.10-dev
 libgstreamer-plugins-base0.10-dev
 libv4l-dev
 libtbb-dev
 libeigen3-dev
 libqt4-dev
 libgtk2.0-dev
 libfaac-dev
 libmp3lame-dev
 libopencore-amrnb-dev
 libopencore-amrwb-dev
 libtheora-dev
 libvorbis-dev
 libxvidcore-dev
 libwebp-dev
 libpng-dev
 libtiff5-dev
 libopenexr-dev
 libgdal-dev
 libx264-dev
 libtiff4-dev
 libvtk6-dev
 libgstreamer*
 libpolarssl-dev
 libnl-utils
 python-dev
 python-numpy
 python-tk
 python3-dev
 python3-tk
 python3-numpy
 x264
 v4l-utils
 qt5-default
 zlib1g-dev
 libtiff-dev
 libtbb2
 ffmpeg
 yasm
'

usage ()
{
  echo "
 Usage:
   $PROGRAM [web|mysql|media|dev]
"
  exit 1
}

log_echo(){
  typeset str="`date +'[%Y/%m/%d %H:%M:%S] '` $@"
  echo -e "${str}" |\
  tr -s ' ' |\
  tee -a ${logfile}
}

[ $# -ne 1 ] && usage || arg=$1
[ `id -u` -ne 0 ] && echo "Please run sudo ${PROGRAM} ${arg}" && exit 1

### apt_reps:

common_apt_reps(){
  log_echo "Setting COMMON apt repository for java"
  log_echo "add-apt-repository -y ppa:webupd8team/java"
  add-apt-repository -y ppa:webupd8team/java | tee -a ${logfile}
}

web_apt_reps(){
  log_echo "Setting WEB apt repository for apache2 and php"
  log_echo "add-apt-repository -y ppa:ondrej/apache2"
  add-apt-repository -y ppa:ondrej/apache2 | tee -a ${logfile}
  log_echo "add-apt-repository -y ppa:ondrej/php"
  add-apt-repository -y ppa:ondrej/php | tee -a ${logfile}
} 

media_apt_reps(){
  log_echo "Setting MEDIA apt repository"
  log_echo "add-apt-repository -y ppa:mc3man/trusty-media"
  add-apt-repository -y ppa:mc3man/trusty-media | tee -a ${logfile}
}

mysql_apt_reps(){
  log_echo "Setting MySQL apt repository - does nothing"
}

### Pre
common_preinstall(){
  log_echo "Running COMMON pre-installation"
  locale-gen "he_IL.UTF-8"
  locale-gen "en_US.UTF-8"
#  dpkg-reconfigure locales
  update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
  dpkg-reconfigure tzdata
  dpkg-statoverride --update --add root sudo 4750 /bin/su
  sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  service ssh restart
}

mysql_preinstall(){
  log_echo "Running MySQL pre-installation"
}


web_preinstall(){
  log_echo "Running WEB pre-installation"
}


media_preinstall(){
  log_echo "Running MEDIA pre-installation"
}


### Post
common_postinstall(){
  typeset profile=/etc/profile.d/java8_variables.sh
  log_echo "Running COMMON post-installation"
  log_echo "update-java-alternatives -s java-8-oracle" &&\
  update-java-alternatives -s java-8-oracle | tee -a ${logfile}

  [  -f ${profile} ] &&\
  [ x"`grep 'JAVA_HOME=/usr/lib/jvm/java-8-oracle' ${profile}`" != "x" ] ||\
  ( log_echo "Updating ${profile}" &&\
    echo '
JAVA_HOME=/usr/lib/jvm/java-8-oracle
JRE_HOME=/usr/lib/jvm/java-8-oracle/jre/bin/java
PATH=$PATH:$HOME/bin:JAVA_HOME:JRE_HOME
' >> ${profile} )
}

web_postinstall(){
  log_echo "Running WEB post-installation"
  typeset apache_conf=/etc/apache2/sites-available/000-default.conf
  [ -f ${apache_conf}.default ] || cp ${apache_conf} ${apache_conf}.default
  cat > ${apache_conf} << EOF
### Created by misi-installer
###
EOF
}

mysql_postinstall(){
  typeset my_cnf=/etc/mysql/my.cnf
  log_echo "Running MySQL post-installation"
  log_echo "MySQL Secure installation. Answers: N, Y, Y, Y, Y"
  log_echo "mysql_secure_installation"
  mysql_secure_installation
  log_echo "Updating the ${my_cnf} file"
  [ -f ${my_cnf}.default ] || \
     cp ${my_cnf} ${my_cnf}.default
  cat > ${my_cnf} << EOF
### Created by misi-installer
###
[client]
port            = 3306
socket          = /var/run/mysqld/mysqld.sock

[mysqld_safe]
socket          = /var/run/mysqld/mysqld.sock
nice            = 0

[mysqld]
user            = mysql
pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
port            = 3306
basedir         = /usr
datadir         = /var/lib/mysql
tmpdir          = /tmp
lc-messages-dir = /usr/share/mysql
skip-external-locking
bind-address            = 127.0.0.1
local-infile            = 0
key_buffer_size         = 16M
max_allowed_packet      = 16M
thread_stack            = 192K
thread_cache_size       = 8
myisam-recover-options  = BACKUP
query_cache_limit       = 1M
query_cache_size        = 16M
log_error               = /var/Misi/Logs/mysql/error.log
expire_logs_days        = 10
max_binlog_size         = 100M

[mysqldump]
quick
quote-names
max_allowed_packet      = 16M

[mysql]
[isamchk]
key_buffer              = 16M
!includedir /etc/mysql/conf.d/
EOF
  
  log_echo "MySQL creating the data base"
  log_echo "cp ${my_cnf} /usr/share/mysql/my-default.cnf"
  cp ${my_cnf} /usr/share/mysql/my-default.cnf
  log_echo "mysql_install_db"
  mysql_install_db
  log_echo "Checkilng the MySQL version"
  log_echo "mysqladmin -p -u root version"
  mysqladmin -p -u root version
}

media_postinstall(){
  typeset src_dir=/tmp/opencv
  typeset opencv_ver="3.2.0"
  typeset opencv_link="https://github.com/Itseez/opencv/archive/${opencv_ver}.zip"
  log_echo "Running MEDIA post-installation"
  log_echo "Compiling and installing OpenCV"
  [ -d ${src_dir} ] && rm -rf  ${src_dir}
  mkdir -p ${src_dir}
  ( [ x${http_proxy} != 'x'  ] && \
       export http_proxy=${http_proxy} && \
       export https_proxy=${http_proxy}
    cd ${src_dir}
    wget ${opencv_link}
    unzip ${opencv_ver}.zip
    cd opencv-${opencv_ver}
    cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local \
          -D WITH_TBB=ON -D BUILD_NEW_PYTHON_SUPPORT=ON -D WITH_V4L=ON \
          -D WITH_QT=ON -D WITH_OPENGL=ON -D WITH_IPP=ON . 
    make 
    make install
  ) | tee -a ${logfile}
  log_echo "Creating link to libippicv.a"
  ( cd /usr/local/lib
    [ -L libippicv.a ] && rm -f libippicv.a
    ln -s ../share/OpenCV/3rdparty/lib/libippicv.a libippicv.a
  ) | tee -a ${logfile}
  log_echo "Updating ld libs"
  [ -f /etc/ld.so.conf.d/opencv.conf ] || \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf
  ldconfig
  log_echo "Creating link from /dev/null to /dev/raw1394"
  [ -f /dev/raw1394 ] && rm -f /dev/raw1394
  ln /dev/null /dev/raw1394
#  log_echo "Testing the OpenCV installation"
  log_echo "Removing the OpenCV source directory"
  rm -rf ${src_dir}
}

### Main
case $arg in
  mysql) categories="mysql"
  ;;
  web) categories="web"
  ;;
  media)  categories="media web"
  ;;
  dev) categories="mysql web media"
  ;;
  *)  echo "The argument ${arg} is not supported" && usage;;
esac
categories="common ${categories}"

#### Installation ###
for ctg in ${categories}
do
  ${ctg}_apt_reps
done

log_echo "apt-key adv --recv-keys --keyserver keys.gnupg.net"
apt-key adv --recv-keys --keyserver keys.gnupg.net | tee -a ${logfile}
log_echo "apt-get update"
apt-get update | tee -a ${logfile}
log_echo "apt-get dist-upgrade --yes"
apt-get dist-upgrade --yes | tee -a ${logfile}

for ctg in ${categories}
do
  ${ctg}_preinstall
  eval "list_pkgs=\$${ctg}_pkgs"
  for pkg in ${list_pkgs}
  do
    log_echo "Installing ${pkg}"
    log_echo "apt-get install -y -q ${pkg}"
    echo "apt-get install -y -q --fix-missing ${pkg}" | tee -a ${logfile}
    apt-get install -y -q --fix-missing ${pkg} | tee -a ${logfile}
  done
  ${ctg}_postinstall
done

log_echo "Done... Enjoy."
exit 0






Looking for linux/videodev.h - not found

Looking for sys/videoio.h - not found

Looking for ffmpeg/avformat.h - not found

package 'libgphoto2' not found

Could NOT find JNI (missing:  JAVA_INCLUDE_PATH JAVA_INCLUDE_PATH2 JAVA_AWT_INCLUDE_PATH)

