#!/bin/bash

# syslogMailer: a script to read stdin and turn each line into an alert
# email typically this is used to read a named-pipe written to by syslog
#
#   example usage: syslogMailer < /etc/syslog.pipes/criticalMessages
#

alertRecipient="fabrice.douchant@gmail.com"      # the mail recipient for alerts
TMOUT=1                                          # don't wait > 1 second for input

# process each line of input and produce an alert email
while read line
do
   # remove any repeated messages
   echo ${line} | grep "message repeated" > /dev/null 2>&1
   if test $? -eq 1
   then
      # send the alert
      echo "${line}" | mailx -A gmail -s "Error on syslog" ${alertRecipient}
   fi
done