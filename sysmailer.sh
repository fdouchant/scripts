#!/bin/bash
# Argument = -p <named pipe> -r <recipients> -s <mail subject [$$HOSTNAME]> -a <mail account [not set]> -t <timeout in sec [1]> -e -f <filter file [not set]> -v -d

usage()
{
cat << EOF
usage: $0 [options]

This script get any messages from the given named pipe and send it by mail (or echo it)

OPTIONS:
  -h   Show this message
  -p   Path to the named pipe. If not provided then read from stdin.
  -r   Email recipients (only used for mailing)
  -s   Email subject (default: the hostname of the machine)
  -a   mail account. If set, use the given mail account (man mail). Otherwise use default mail configuration. (default: not set)
  -t   Timeout if no message in pipe (default: 1)
  -e   Echo instead of sending email
  -f   Filter file. If set, each line of the file works as a filter. Each event matching a filter will be skipped. (default: not set)
  -m   Mail command to use (default: s-nail)
  -v   Verbose
  -d   Debug
EOF
}

NAMED_PIPE=
RECIPIENTS=
SUBJECT=$HOSTNAME
ACCOUNT=
TMOUT=1 # bash variable to set read timeout
ECHO=0
FILTER=
VERBOSE=0
STDIN=0
MAIL_CMD=s-nail
while getopts "hp:r:s:a:t:ef:vd" OPTION
do
    case $OPTION in
        h)
            usage
            exit 1
            ;;
        p)
            NAMED_PIPE=$OPTARG
            ;;
        r)
            RECIPIENTS=$OPTARG
            ;;
        s)
            SUBJECT=$OPTARG
            ;;
        a)
            ACCOUNT=$OPTARG
            ;;
        t)
            TMOUT=$OPTARG
            ;;
        e)
            ECHO=1
            ;;
        f)
            FILTER=$OPTARG
            ;;
        v)
            VERBOSE=1
            ;;
        d)
            set -x
            ;;
        m)
            MAIL_CMD=$OPTARG
            ;;
        ?)
            usage
            exit 1
            ;;
    esac
done
# remove options
shift $(($OPTIND - 1))

# mandatory parameters
if [ -z "$NAMED_PIPE" ]; then
    if [ $VERBOSE -eq 1 ]; then echo "Using stdin as no pipe has been proveded (-p parameter)"; fi
    STDIN=1
fi
if [ $ECHO -eq 0 -a -z "$RECIPIENTS" ]; then
    echo "ERROR: -r option is mandatory if -e option is not set"
    echo
    usage
    exit 1
fi
if [ -n "$FILTER" -a ! -e "$FILTER" ]; then
    echo "ERROR: -f requires a readable file"
    echo
    usage
    exit 1
fi

# mail account
if [ -n "$ACCOUNT" ]; then
    ACCOUNT="-A $ACCOUNT"
fi

# function to process each line
function process_line {
    # remove any repeated messages
    echo "$1" | grep "message repeated" > /dev/null 2>&1
    repeated=$?
    # remove filtered message
    filtered=1
    if [ -n "$FILTER" ]; then
        echo "$1" | grep --file=$FILTER > /dev/null 2>&1
        filtered=$?
        # verbose
        if [ $VERBOSE -eq 1 -a $filtered -eq 0 ]; then echo "Message filtered: $1"; fi
    fi

    if [ $repeated -eq 1 -a $filtered -eq 1 ]; then
        # echo message
        if [ $ECHO -eq 1 ]; then
            echo "${SUBJECT}: $1"
        # send the alert
        else
            echo "$1" | $MAIL_CMD ${ACCOUNT} -s "${SUBJECT}" ${RECIPIENTS}
        fi
    fi

}

# process each line of input and produce an alert email
if [ $STDIN -eq 0 ]; then
    while read line < $NAMED_PIPE; do
        process_line "$line"
    done
else
    while read line; do
        process_line "$line"
    done
fi

# unset debugger
set +x
