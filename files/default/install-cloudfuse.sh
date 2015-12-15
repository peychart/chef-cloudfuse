#!/bin/bash
# Instalation de cloudfuse à partir d'un node standard
#PE-20140707
SERVICE=cloudfuse
MYNAME=${MYNAME:-install-$SERVICE.sh}
MYTMP="/tmp/.$MYNAME.$(date +%Y%m%d.%H%M%S)"
trap "rm -f $MYTMP" 0 1 2 3 5
rouge='\e[0;31m'; vert='\e[0;32m'; jaune='\e[1;33m'; bleu='\e[0;34m'; neutre='\e[0;m';
print() { color=$1; shift; if [ _$(basename $SHELL) = "_bash" ]; then echo -e "${color}$* ${neutre}"; else echo "$*"; fi; }
printstd() { print "${vert}" "$MYNAME: $*"; }
printerr() { print "${rouge}" "$MYNAME: $*" 2>&1; }
printwrn() { print "${jaune}" "$MYNAME: $*"; }
printhlp() { print "${bleu}" "$*"; }
export DEBIAN_FRONTEND=noninteractive

giturl=${giturl:-https://github.com/redbo/cloudfuse.git}
tenant=${tenant:-system}
user=${user:-root}
password=${password:-testpass}
authurl=${authurl:-http://swiftauth:8080/auth/v1.0}
mountpoint=${mountpoint:-/media/cloudfuse}

# Analyse des arguments:
while getopts h opt
do case "$opt" in
    h|\?) #unknown flag
       printhlp "syntaxe: $MYNAME [ <git_url_for_cloudfuse> (default is https://github.com/redbo/cloudfuse.git) ]"
       printhlp
       printhlp "eg.   curl -sfH \"X-Auth-Token: <X_Auth_Token>\" \\"
       printhlp "          <X-Storage-Url>/os-bootstrap/$MYNAME \\"
       printhlp "        | bash -s -- <git_url_for_cloudfuse>"
       printhlp
       printhlp "from: curl -is -H \"X-Auth-User: system:root\" \\"
       printhlp "               -H \"X-Auth-Key: testpass\" \\"
       printhlp "               http://swiftauth:8080/auth/v1.0"
       printhlp
       exit 0;;
esac done
shift `expr $OPTIND - 1`
! whoami | grep -qsw root && printerr "must be root to do that..." && exit 1
[ $# -ne 0 ] && giturl=$1 && shift
[ $# -ne 0 -o -z "$giturl" ] && printerr "bad argument... (see: -h)" && exit 1

insertLineInFile() { # syntaxe: $0 "line" fileName [numLine]
 [ -z "$2" -o ! -w $2 ] && return 1
 local n=${3:-0}
 ([ 0$n -ne 0 ] && head -n $(expr $n - 1) <$2) >$MYTMP
 echo $1 >>$MYTMP
 tail -n +$n <$2 >>$MYTMP
 [ 0$(expr $(wc -l <$2) + 1) -eq 0$(wc -l <$MYTMP) ] \
  && cat <$MYTMP >$2
}

# install cloudfuse:
if ! command -v cloudfuse >/dev/null; then
  echo "# *********** Generated by the \"apt_get install git\" command:" >/tmp/$MYNAME.log
  ! apt-get -q install git build-essential libcurl4-openssl-dev libxml2-dev libxml++2.6-dev libssl-dev libfuse-dev gcc -y --force-yes >>/tmp/$MYNAME.log 2>&1 \
    && printerr "git install error (see: /tmp/$MYNAME.log)..." && exit 1
  echo "# *********** Generated by the \"clone cloudfuse\" procedure:" >>/tmp/$MYNAME.log
  cd /tmp && rm -rf cloudfuse
  ! git clone $giturl cloudfuse >>/tmp/$MYNAME.log 2>&1 \
    && printerr "cloudfuse clone aborted (see: /tmp/$MYNAME.log)..." && exit 1
  cd -
  echo "# *********** Generated by the \"compile cloudfuse\" procedure:" >>/tmp/$MYNAME.log
  (cd /tmp/cloudfuse && ./configure && make install) >>/tmp/$MYNAME.log 2>&1
  [ $? -ne 0 ] && printerr "cloudfuse compile error (see: /tmp/$MYNAME.log)..."
  printstd "$SERVICE installation ended."
else
  printwrn "$SERVICE was already installed..."
fi
! command -v cloudfuse >/dev/null \
  && printerr "$SERVICE cannot be install..." && exit 1

# Définition des parametres de connexion cloudfuse:
CONFile=/root/.cloudfuse
cat >$CONFile << @@@
username=$tenant:$user
password=$password
authurl=$authurl
@@@
[ $? -ne 0 ] \
 && printerr "cannot edit \"$CONFile\"" && exit 1

# Definition de la partition cloudfuse dans fstab:
CONFile=/etc/fstab
grep -qsw "^cloudfuse" $CONFile \
 || echo "cloudfuse       $mountpoint fuse   noauto,user,allow_other  0  0" >>$CONFile
[ $? -ne 0 ] \
 && printerr "cannot edit \"$CONFile\"" && exit 1

# lancement automatique de la partition cloudfuse:
CONFile=/etc/rc.local
if ! grep -Pvs "^[ \t]*#" <$CONFile| grep -sw mount| grep -qsw cloudfuse ; then
    num=$(grep -nsw exit $CONFile| tail -n 1| cut -d':' -f1)
    if [ 0$num -ne 0 ]; then
        insertLineInFile "mkdir -p $mountpoint; mount cloudfuse" $CONFile $num
fi  fi
! grep -Pvs "^[ \t]*#" <$CONFile| grep -sw mount| grep -qsw cloudfuse \
 && printerr "cannot edit \"$CONFile\"" && exit 1


# Do the iptable rules:
CONFile=/etc/iptables.d/filter/INPUT/$SERVICE
mkdir -p $(dirname $CONFile); cat >$CONFile <<@@@
# Dynamic file generated by chef
#     DO NOT EDIT THIS FILE BY HAND -- YOUR CHANGES WILL BE OVERWRITTEN
--protocol tcp --dport 111 --sport 1024:65535 --match state --state NEW --jump ACCEPT
@@@
[ $? -ne 0 ] \
 && printerr "cannot edit \"$CONFile\"" && exit 1

# Montage de la resource cloudfuse:
printstd "\nTry to mount ressource..."
mkdir -p $mountpoint; mount| grep -qsw '^cloudfuse' || mount $mountpoint || exit 1

printstd "$SERVICE succefully configured."

