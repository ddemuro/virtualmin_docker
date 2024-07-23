#!/bin/bash
DIR='/home'
for dir in `ls $DIR`;
do
    for subdir in `ls $DIR/$dir/homes`;
    do
      python /opt/scripts/maildupli.py -d -S 0 "$DIR/$dir/homes/$subdir/Maildir"
      python /opt/scripts/maildupli.py -d -S 0 "$DIR/$dir/homes/$subdir/Maildir/.*"
    done
done
