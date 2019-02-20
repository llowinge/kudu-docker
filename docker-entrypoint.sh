#!/bin/bash
set -e

function do_help {
  echo HELP:
  echo "Supported commands:"
  echo "   master              - Start a Kudu Master"
  echo "   tserver             - Start a Kudu TServer"
  echo "   single              - Start a Kudu Master+TServer in one container"
  echo "   kudu                - Run the Kudu CLI"
  echo "   help                - print useful information and exit"
  echo ""
  echo "Other commands can be specified to run shell commands."
  echo "Set the environment variable KUDU_OPTS to pass additional"
  echo "arguments to the kudu process. DEFAULT_KUDU_OPTS contains"
  echo "a recommended base set of options."

  exit 0
}

function uid_entrypoint {
  if ! whoami &> /dev/null; then
    if [ -w /etc/passwd ]; then
      echo "${USER_NAME:-default}:x:$(id -u):0:${USER_NAME:-default} user:${HOME}:/sbin/nologin" >> /etc/passwd
    fi
  fi
}

DEFAULT_KUDU_OPTS="-logtostderr \
 -fs_wal_dir=/var/lib/kudu/$1 \
 -fs_data_dirs=/var/lib/kudu/$1 \
 -use_hybrid_clock=false"

KUDU_OPTS=${KUDU_OPTS:-${DEFAULT_KUDU_OPTS}}

if [ "$1" = 'master' ]; then
  exec kudu-master  ${KUDU_OPTS}
elif [ "$1" = 'tserver' ]; then
  exec kudu-tserver -tserver_master_addrs ${KUDU_MASTER} ${KUDU_OPTS}
elif [ "$1" = 'single' ]; then
  uid_entrypoint

  KUDU_MASTER=127.0.0.1:7051
  KUDU_MASTER_OPTS="-logtostderr \
   -fs_wal_dir=/var/lib/kudu/master \
   -fs_data_dirs=/var/lib/kudu/master \
   -use_hybrid_clock=false"
  KUDU_TSERVER_OPTS="-logtostderr \
   -fs_wal_dir=/var/lib/kudu/tserver \
   -fs_data_dirs=/var/lib/kudu/tserver \
   -use_hybrid_clock=false"
  exec bash -c 'sleep 10; java -cp kudu-client-1.0-SNAPSHOT.jar syndesis.org.App' &
  exec kudu-master ${KUDU_MASTER_OPTS} &
  sleep 5
  exec kudu-tserver -tserver_master_addrs ${KUDU_MASTER} ${KUDU_TSERVER_OPTS}
elif [ "$1" = 'kudu' ]; then
  shift; # Remove first arg and pass remainder to kudu cli
  exec kudu "$@"
elif [ "$1" = 'help' ]; then
  do_help
fi

exec "$@"
