#!/usr/bin/env bash
 
PROGRAM=`echo $0 | sed 's?.*/??'`
logfile=${PROGRAM}_`date +%Y%m%d-%H%M%S`
 
if [ `id -u` -ne 0 ]; then
  echo "Please run sudo ${PROGRAM}"
  exit 1
fi
 
usage ()
{
  echo "
Usage:
   $PROGRAM [mysql|apache|java|all]
"
  exit 1
}
 
log_echo(){
  typeset str="`date +'[%Y/%m/%d %H:%M:%S] '` $@"
  echo -e "${str}" |\
  tr -s ' ' |\
  tee -a ${logfile}
}
 
 
[[ $# -ne 1 ]] && usage || arg=$1
 
case $arg in
  mysql) packages='mysql-server'
  ;;
  apache) packages='apache2 php7.0 libapache2-mod-php7.0'
  ;;
  java)  packages='default-jdk'
  ;;
  all)   packages='mysql-server
                   apache2 php7.0 libapache2-mod-php7.0
                   default-jdk'
  ;;
  *)  echo "The argument ${arg} is not supported" && usage;;
esac
 
#### Installation ###
for pkg in ${packages}
do
  log_echo "Installing ${pkg}"
  log_echo "apt-get install -y -q ${pkg}"
  apt-get install -y -q ${pkg} | tee -a ${logfile}
done
 
exit 0
