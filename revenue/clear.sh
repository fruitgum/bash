#!/bin/bash
rm -f WORK cid* S1 S2 S3 S4 S5 rmsh rsh
kill -l 9 $(ps aux | grep cid_rev_ | grep -v grep | awk '{ print $2 }')
kill -l 9 $(ps aux | grep cid_pos_ | grep -v grep | awk '{ print $2 }')
pkill -9 tail
sleep 5
echo 'Cleaned!'

