#!/usr/bin/env bash
#
# Logstash  start/stop script
#

# USE_RUBY=1 to force use the local "ruby" command to launch logstash instead of using the vendored JRuby
# USE_DRIP=1 to force use drip
# DEBUG=1 to output debugging information


retVal=0

if [[ -f /usr/bin/nawk ]] ; then
  AWK=/usr/bin/nawk
else
  AWK=awk
fi

if [[ -z $1 ]] ; then
  echo "[ ERROR ]  Service Command Not Provided." >&2
  echo "Usage:   ./logstash_control.sh  <command>" >&2
  retVal=1
else
  svccmd="$1"
fi

if [[ -d /opt/csw/java ]] ; then
  if   [[ -d /opt/csw/java/jre/jre8/bin ]] ; then
    JAVA_HOME=/opt/csw/java/jre/jre8
  elif [[ -d /opt/csw/java/jdk/jdk8/bin ]] ; then
    JAVA_HOME=/opt/csw/java/jdk/jdk8
  elif [[ -d /opt/csw/java/jdk1.8.0_102/bin ]] ; then
    JAVA_HOME=/opt/csw/java/jdk1.8.0_102
  elif [[ -d /opt/csw/java/jdk1.8.0_92/bin ]] ; then
    JAVA_HOME=/opt/csw/java/jdk1.8.0_92
  fi
fi
if [[ -z "$JAVA_HOME" ]] && [[ -d /usr/local/gnsms/arch-i86pc/java/bin ]] ; then
  JAVA_HOME=/usr/local/gnsms/arch-i86pc/java
fi
export JAVA_HOME

#
# LS_JVM_OPTS="xxx"
#     path to file with JVM options
#
LS_JVM_OPTS="${SCRIPTDIR}/settings/Logstash.jvm.options"

#
# LS_JAVA_OPTS="xxx"
#     to append extra options to the defaults JAVA_OPTS provided by logstash
#
#LS_JAVA_OPTS="xxx"

#
# not using JAVA_OPTS
# JAVA_OPTS="xxx" 
#     *completely override* the default JAVA_OPTS provided by logstash
#JAVA_OPTS="xxx"


GNSMS=/usr/local/gnsms
ETCDIR=${GNSMS}/etc
SCRIPTDIR=${GNSMS}/scripts
export  GNSMS  ETCDIR  SCRIPTDIR

CLIENTNAME=`cat /etc/clientname`
CETCDIR=${GNSMS}/etc/clients/${CLIENTNAME}
export  CLIENTNAME  CETCDIR

#
# set Logstash Home and Temp paths
#
if [[ -z "$LS_HOME" ]] ; then
  LS_HOME=${SCRIPTDIR}/logstash
fi
#if [[ -z "$LS_PATH_TMP" ]] ; then
if [[ "$(${AWK} -F'/' '($2 == "tmp") {print "1"}' <<<${LS_HOME})" != 1 ]] ; then
  # LS_PATH_TMP is not a standard path, only used internally.
  LS_PATH_TMP=/tmp/logstash

  # create temp dir, if nonexistent
  if [[ ! -d ${LS_PATH_TMP} ]] ; then
    mkdir -p ${LS_PATH_TMP}
    retVal="$?"
  fi
fi



#
# ensure we have a HOSTNAME
#
if [[ -z $HOSTNAME ]] ; then
  HOSTNAME=$(uname -n | ${AWK} -F'.' '{print $1}')
fi
args="${args} --node.name=${HOSTNAME}"


#
# set Logstash path.logs
#
if [[ -z "$LS_PATH_LOGS" ]] ; then
  LS_PATH_LOGS=${LS_PATH_TMP:-/tmp/logstash}/logs
fi
args="${args} --path.logs=${LS_PATH_LOGS:-/tmp/logstash}"

#
# set Logstash path.data
#
if [[ -z "$LS_PATH_DATA" ]] ; then
  LS_PATH_DATA=${LS_PATH_TMP:-/tmp/logstash}/data
fi
args="${args} --path.data=${LS_PATH_DATA:-/tmp/logstash}"

#
# from $LS_HOME/config/startup.options:  LS_PIDFILE=/var/run/logstash.pid
#
if [[ -z "$LS_PIDFILE" ]] && [[ -d "$LS_PATH_TMP" ]] ; then
  LS_PIDFILE=${LS_PATH_TMP:-/tmp/logstash}/logstash.pid
  export LS_PIDFILE
fi

#
# set Logstash path.config (really, it's a file)
#
if [[ -f ${CETCDIR}/logstash-agent-${HOSTNAME:-generic}.conf ]] ; then
  LS_PATH_CONFIG=${CETCDIR}/logstash-agent-${HOSTNAME:-${_Hostname}}.conf
fi
if [[ -z "$LS_PATH_CONFIG" ]] ; then
  LS_PATH_CONFIG=${ETCDIR}/logstash-agent-generic.conf
fi
if [[ -f "$LS_PATH_CONFIG" ]] || [[ -d "$LS_PATH_CONFIG" ]] ; then
  args="${args} --path.config=${LS_PATH_CONFIG}"
fi

#
# set Logstash config.reload.automatic
#   to disable, set config.reload.interval as negative value
#
if [[ -z "$LS_CONFIG_RELOAD" ]] ; then
  args="${args} --config.reload.automatic"
  #echo "Config Reload Interval will use default setting" >&2
elif [[ "$LS_CONFIG_RELOAD" > 0 ]] ; then
  args="${args} --config.reload.automatic"
  args="${args} --config.reload.interval=${LS_CONFIG_RELOAD:-3}"
elif [[ "$LS_CONFIG_RELOAD" < 0 ]] ; then
  echo "Config Reload Disabled" >&2
#else
#  echo "[ INFO ]  Not setting --config.reload.automatic" >&2
fi

#
# set Logstash log.level   (NOTE: "quiet" is not valid)
#
if [[ -n "$LS_LOGLEVEL" ]] ; then
  args="${args} --log.level=${LS_LOGLEVEL:-info}"
fi

test_args="--config.test_and_exit"
  
_bash=`which bash`

command="${_bash:-bash} ${LS_HOME}/bin/logstash"


logstash_check() {
    if [[ -n $DEBUG ]] ; then
      echo "command:  ${command}"
      echo "args:  ${args}"
      echo "test_args:  ${test_args}"
    fi

    ${command} ${args} ${test_args} > ${LS_PATH_TMP:-/tmp/logstash}/check.out 2>&1&

    tail -f ${LS_PATH_TMP:-/tmp/logstash}/check.out
}

logstash_status() {
  # collect the "remembered" pid from LS_PIDFILE
  if [[ -f "${LS_PIDFILE:-/tmp/logstash/logstash.pid}" ]] ; then
    #echo "Logstash PID:  $(cat ${LS_PIDFILE:-/tmp/logstash/logstash.pid})"
    ps -p $(cat ${LS_PIDFILE:-/tmp/logstash/logstash.pid}) &> /dev/null \
      && echo "Logstash is running.  (PID: $(cat ${LS_PIDFILE:-/tmp/logstash/logstash.pid}))"
  elif [[ "$DEBUG" > 0 ]] ; then
    echo "[ ERROR ]  LS_PIDFILE Not Found:  ${LS_PIDFILE}"
    stat "${LS_PIDFILE:-/tmp/logstash/logstash.pid}"
  else
    echo "Logstash is NOT running."
  fi
}


logstash_start() {
  # do start Logstash
  ${command} ${args} > ${LS_PATH_TMP:-/tmp/logstash}/startup.out 2>&1&
  sleep 20
  ps -ef |${AWK} '($8 ~ /java/) {print $2}' > ${LS_PIDFILE:-/tmp/logstash/logstash.pid}
}

#logstash_start() {
#  nohup ${command} ${args} > ${LS_PATH_TMP:-/tmp/logstash}/startup.out 2>&1&
#}


logstash_stop() {
  echo -n "Stopping Logstash."

  if [[ -f "${LS_PIDFILE:-/tmp/logstash/logstash.pid}" ]] ; then
    echo -n "."
    #echo "LS_PIDFILE:    ${LS_PIDFILE}"
    #echo "Logstash pid:  $(cat ${LS_PIDFILE})"

    kill $(cat ${LS_PIDFILE:-/tmp/logstash/logstash.pid})

    # keep testing the pid until it's not running
    while true ; do
      echo -n "."

      ps -p $(cat ${LS_PIDFILE:-/tmp/logstash/logstash.pid}) \
        || break

      sleep 1
    done

    echo "stopped"

    # remove the pidfile, as we are confident Logstash is stopped
    rm ${LS_PIDFILE}

  else
    echo "[ ERROR ]  LS_PIDFILE Not Found:  ${LS_PIDFILE}"
    stat "${LS_PIDFILE:-/tmp/logstash/logstash.pid}"
  fi 

}


logstash_help() {
  cat <<"HELP"
Usage:
    bin/logstash [OPTIONS]

Options:
    -n, --node.name NAME          Specify the name of this logstash instance

    -f, --path.config CONFIG_PATH Load the logstash config from a specific file
                                  or directory
    -e, --config.string CONFIG_STRING Use the given string as the configuration
                                  data. Same syntax as the config file.
    --modules MODULES             Load Logstash modules.

    -M, --modules.variable MODULES_VARIABLE Load variables for module template.

    -w, --pipeline.workers COUNT  Sets the number of pipeline workers to run.
                                   (default: 32)
    -b, --pipeline.batch.size SIZE Size of batches the pipeline is to work in.
                                   (default: 125)
    -u, --pipeline.batch.delay DELAY_IN_MS When creating pipeline batches, how long to
                                  wait while polling for the next event. (default: 5)
    --pipeline.unsafe_shutdown    Force logstash to exit during shutdown even
                                  if there are still inflight events in memory.
    --path.data PATH              This should point to a writable directory.
                                   (default: "/usr/local/gnsms/scripts/logstash/data")
    -p, --path.plugins PATH       A path of where to find plugins.
                                   (default: [])
    -l, --path.logs PATH          Write logstash internal logs to the given
                                  file, else logstash will emit to stdout.
    --log.level LEVEL             Set the log level for logstash. Possible values are:
                                    quiet,fatal,error,warn,info,debug,trace
    --config.debug                Print the compiled config ruby code out as a debug log
                                   (you must also have --log.level=debug enabled).
    -i, --interactive SHELL       Drop to shell instead of running as normal.
                                  Valid shells are "irb" and "pry"
    -V, --version                 Emit the version of logstash and its friends,
                                  then exit.
    -t, --config.test_and_exit    Check configuration for valid syntax and then exit.
                                   (default: false)
    -r, --config.reload.automatic Monitor configuration changes and reload when changed.
                                   (default: false)
    --config.reload.interval RELOAD_INTERVAL How frequently to poll the configuration location
                                  for changes, in seconds.  (default: 3)
    --http.host HTTP_HOST         Web API binding host (default: "127.0.0.1")
    --http.port HTTP_PORT         Web API http port (default: 9600..9700)
    --log.format FORMAT           Specify if Logstash should write its own logs in JSON form (one
                                  event per line) or in plain text (using Ruby's Object#inspect)
    --path.settings SETTINGS_DIR  Directory containing logstash.yml file. This can also be
                                  set through the LS_SETTINGS_DIR environment variable.

    -h, --help                    print help
HELP

}
#echo "this PID:  $$"

logstash_${svccmd}

exit $retVal

