#!/sbin/openrc-run

name="logstash"

extra_commands="configtest console" 
extra_started_commands="upgrade reload"

description="Stash the logs."
description_configtest="Run logstash' internal config check."
description_upgrade="Upgrade the logstash binary without losing connections."
description_reload="Reload the logstash configuration without losing connections."

LS_HOME='/usr/local/share/logstash'
#LS_SETTINGS_DIR='/opt/logstash/etc'

LS_TMP="/tmp/logstash"
LS_CONFIG_FILE="${LS_CONFIG_FILE:-${LS_SETTINGS_DIR:-${LS_HOME}/config}/logstash.conf}"
##  many start/settings are defined in "$LS_SETTINGS_DIR/logstash.yml"

#LS_JAVA_OPTS=""  ## path to file with JVM options
#LS_JVM_OPTS=""   ## to append extra options to defaults JAVA_OPTS
#JAVA_OPTS=""     ## to completely override defaults JAVA_OPTS

#USE_RUBY=1      ## force use the local "ruby" command to launch logstash, instead of vendor JRuby
#USE_DRIP=1      ## force to use drip
#DEBUG=1         ## output debugging info

command="${LS_HOME}/bin/logstash"
command_args=" --config.reload.automatic "

pidfile=${pidfile:-/var/run/${name}/${name}.pid}
user=${user:-logstash}
group=${group:-logstash}


start_pre() {
    LS_LOG_DIR=${LS_LOG_DIR:-${LS_HOME}/logs}

    command_background=1
    command_progress=1
    command_user=${user:-logstash}

    command_args="${command_args} --path.logs ${LS_LOG_DIR}"
    if [ "${RC_CMD}" != "restart" ]; then
        configtest || return 1
    fi
}

stop_pre() {
    if [ "${RC_CMD}" = "restart" ]; then
        configtest || return 1
    fi
}

reload() {
    configtest || return 1
    ebegin "Refreshing logstash' configuration"
    kill -HUP `cat ${pidfile}` &>/dev/null
    eend $? "Failed to reload logstash"
}

upgrade() {
    configtest || return 1
    ebegin "Upgrading logstash"

    einfo "Sending USR2 to old binary"
    kill -USR2 `cat ${pidfile}` &>/dev/null

    einfo "Sleeping 3 seconds before pid-files checking"
    sleep 3

    if [ ! -f ${pidfile}.oldbin ]; then
        eerror "File with old pid not found"
        return 1
    fi

    if [ ! -f ${pidfile} ]; then
        eerror "New binary failed to start"
        return 1
    fi

    einfo "Sleeping 3 seconds before WINCH"
    sleep 3 ; kill -WINCH `cat ${pidfile}.oldbin`

    einfo "Sending QUIT to old binary"
    kill -QUIT `cat ${pidfile}.oldbin`

    einfo "Upgrade completed"
    eend $? "Upgrade failed"
}

configtest() {
    checkpath -q -d -m 0755 -o root:wheel /${LS_HOME}

    checkpath -q -d -m 0750 -o ${user}:${group} ${LS_HOME}/data

    checkpath -q -d -m 0755 -o ${user}:${group} ${LS_HOME}/logs
####  sudo pw groupadd -n logstash -g 998
####  sudo pw useradd -n logstash -u 999 -c "Logstash Service User" -d /opt/logstash -s /sbin/nologin -g logstash

    if [ -z $LS_SETTINGS_DIR ] ; then
        LS_SETTINGS_DIR="${LS_HOME}/config"
    fi
    checkpath -q -d -m 0755 -o ${user}:${group} ${LS_SETTINGS_DIR}

    ## ${LS_HOME}/tmp  could be a symlink to "/tmp/logstash"
    if [ ! -z ${LS_TMP} ] ; then
        LS_TMP="${LS_HOME}/tmp"
    fi
    checkpath -q -d -m 0755 -o ${user}:${group} ${LS_TMP:-${LS_HOME}/tmp}

    if [ ! -f "${LS_CONFIG_FILE}/logstash.conf" ] ; then
        command_args="${command_args} --path.config ${LS_CONFIG_FILE}"
    fi

    ebegin "Checking logstash' configuration"

    ${command} ${command_args} --config.test_and_exit

    if [ $? -ne 0 ]; then
        ${command} ${command_args}
    fi

    eend $? "failed, please correct errors above"
}

# Drop to shell instead of running as normal.
console() {

    start-stop-daemon --start \
      -- ${command} ${command_args} --interactive pry
    eend $? "failed, "
}

##  Usage:
##      bin/logstash [OPTIONS]
##  
##  Options:
##  
##      -n, --node.name NAME          Specify the name of this logstash instance, if no value is given
##                                    it will default to the current hostname.
##                                     (default: "gns-apex-01")
##  
##      -f, --path.config CONFIG_PATH Load the logstash config from a specific file
##                                    or directory.  If a directory is given, all
##                                    files in that directory will be concatenated
##                                    in lexicographical order and then parsed as a
##                                    single config file. You can also specify
##                                    wildcards (globs) and any matched files will
##                                    be loaded in the order described above.
##  
##      -e, --config.string CONFIG_STRING Use the given string as the configuration
##                                    data. Same syntax as the config file. If no
##                                    input is specified, then the following is
##                                    used as the default input:
##                                    "input { stdin { type => stdin } }"
##                                    and if no output is specified, then the
##                                    following is used as the default output:
##                                    "output { stdout { codec => rubydebug } }"
##                                    If you wish to use both defaults, please use
##                                    the empty string for the '-e' flag.
##                                     (default: nil)
##  
##      -w, --pipeline.workers COUNT  Sets the number of pipeline workers to run.
##                                     (default: 4)
##  
##      -b, --pipeline.batch.size SIZE Size of batches the pipeline is to work in.
##                                     (default: 125)
##  
##      -u, --pipeline.batch.delay DELAY_IN_MS When creating pipeline batches, how long to wait while polling
##                                    for the next event.
##                                     (default: 5)
##  
##      --pipeline.unsafe_shutdown    Force logstash to exit during shutdown even
##                                    if there are still inflight events in memory.
##                                    By default, logstash will refuse to quit until all
##                                    received events have been pushed to the outputs.
##                                     (default: false)
##  
##      --path.data PATH              This should point to a writable directory. Logstash
##                                    will use this directory whenever it needs to store
##                                    data. Plugins will also have access to this path.
##                                     (default: "/usr/local/logstash-5.1.1/data")
##  
##      -p, --path.plugins PATH       A path of where to find plugins. This flag
##                                    can be given multiple times to include
##                                    multiple paths. Plugins are expected to be
##                                    in a specific directory hierarchy:
##                                    'PATH/logstash/TYPE/NAME.rb' where TYPE is
##                                    'inputs' 'filters', 'outputs' or 'codecs'
##                                    and NAME is the name of the plugin.
##                                     (default: [])
##  
##      -l, --path.logs PATH          Write logstash internal logs to the given
##                                    file. Without this flag, logstash will emit
##                                    logs to standard output.
##                                     (default: "/usr/local/logstash-5.1.1/logs")
##  
##      --log.level LEVEL             Set the log level for logstash. Possible values are:
##                                      - fatal
##                                      - error
##                                      - warn
##                                      - info
##                                      - debug
##                                      - trace
##                                     (default: "info")
##  
##      --config.debug                Print the compiled config ruby code out as a debug log (you must also have --log.level=debug enabled).
##                                    WARNING: This will include any 'password' options passed to plugin configs as plaintext, and may result
##                                    in plaintext passwords appearing in your logs!
##                                     (default: false)
##  
##      -i, --interactive SHELL       Drop to shell instead of running as normal.
##                                    Valid shells are "irb" and "pry"
##  
##      -V, --version                 Emit the version of logstash and its friends,
##                                    then exit.
##  
##      -t, --config.test_and_exit    Check configuration for valid syntax and then exit.
##                                     (default: false)
##  
##      -r, --config.reload.automatic Monitor configuration changes and reload
##                                    whenever it is changed.
##                                    NOTE: use SIGHUP to manually reload the config
##                                     (default: false)
##  
##      --config.reload.interval RELOAD_INTERVAL How frequently to poll the configuration location
##                                    for changes, in seconds.
##                                     (default: 3)
##  
##      --http.host HTTP_HOST         Web API binding host (default: "127.0.0.1")
##  
##      --http.port HTTP_PORT         Web API http port (default: 9600..9700)
##  
##      --log.format FORMAT           Specify if Logstash should write its own logs in JSON form (one
##                                    event per line) or in plain text (using Ruby's Object#inspect)
##                                     (default: "plain")
##  
##      --path.settings SETTINGS_DIR  Directory containing logstash.yml file. This can also be
##                                    set through the LS_SETTINGS_DIR environment variable.
##                                     (default: "/usr/local/logstash-5.1.1/config")
##  
##  DEPRECATED
##      --verbose                     Set the log level to info.
##                                    DEPRECATED: use --log.level=info instead.
##  DEPRECATED
##      --debug                       Set the log level to debug.
##                                    DEPRECATED: use --log.level=debug instead.
##  DEPRECATED
##      --quiet                       Set the log level to info.
##                                    DEPRECATED: use --log.level=quiet instead.
