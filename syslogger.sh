#!/bin/bash
# Argument = -e <error_priority [user.err]> -s <success_priority>

usage()
{
cat << EOF
usage: $0 [options] command

This script run the given command and log error and/or success to syslog.

OPTIONS:
  -h   Show this message
  -e   The priority to log on command error (default: user.err)
  -s   The priority to log on command success. If not set success will not be logged
EOF
}

ERROR_PRIORITY=user.err
SUCCESS_PRIORITY=
while getopts "he:s:" OPTION
do
    case $OPTION in
        h)
            usage
            exit 1
            ;;
        e)
            ERROR_PRIORITY=$OPTARG
            ;;
        s)
            SUCCESS_PRIORITY=$OPTARG
            ;;
        ?)
            usage
            exit 1
            ;;
    esac
done
# remove options
shift $((OPTIND-1))

# keep 
ERROR_FILE=$(mktemp)
SUCCESS_FILE=$(mktemp)
# run command
$@ 2>$ERROR_FILE 1>$SUCCESS_FILE
CODE=$?

if [[ $CODE -eq 0 ]]; then
    # command is ok
    cat $SUCCESS_FILE
    if [ -n "$SUCCESS_PRIORITY" ]; then
        # log success
        logger -t $1 -p $SUCCESS_PRIORITY -- [$@] $(cat $SUCCESS_FILE)
    fi
else
    # command is NOK
    cat $ERROR_FILE
    logger -t $1 -p $ERROR_PRIORITY -- [$@] $(cat $ERROR_FILE)
fi
rm $ERROR_FILE; rm $SUCCESS_FILE
exit $CODE
