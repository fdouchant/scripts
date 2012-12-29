#!/bin/bash
# Argument = -p <named pipe> -r <recipients> -s <mail subject [named pipe name OR $$HOSTNAME]> -a <mail account [not set]> -t <timeout in sec [1]> -e

usage()
{
cat << EOF
usage: $0 [options]

This script get any messages from the given named pipe and send it by mail (or echo it)

OPTIONS:
  -h   Show this message
  -p   Path to the named pipe
  -r   Email recipients (only used for mailing)
  -s   Email subject (default: the hostname of the machine)
  -a   mail account. If set, use the given mail account (man mail). Otherwise use default mail configuration. (default: not set)
  -t   Timeout if no message in pipe (default: 1)
  -e   Echo instead of sending email
EOF
}

NAMED_PIPE=
RECIPIENTS=
SUBJECT=$HOSTNAME
ACCOUNT=
TMOUT=1
ECHO=0
while getopts "hp:r:s:a:t:e" OPTION
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
    echo "ERROR: -p option is mandatory"
    echo
    usage
    exit 1
fi
if [ $ECHO -eq 0 -a -z "$RECIPIENTS" ]; then
    echo "ERROR: -r option is mandatory if -e option is not set"
    echo
    usage
    exit 1
fi

# mail account
if [ -z "$ACCOUNT" ]; then
    ACCOUNT="-A $ACCOUNT"
fi

# process each line of input and produce an alert email
while read line < $NAMED_PIPE
do
    # remove any repeated messages
    echo ${line} | grep "message repeated" > /dev/null 2>&1
    if test $? -eq 1
    then
        # echo message
        if [ $ECHO -eq 1 ]; then
            echo ${SUBJECT}: ${line}
        else
        # send the alert
            echo "${line}" | mailx ${ACCOUNT} -s "${SUBJECT}" ${RECIPIENTS}
        fi
    fi
done
