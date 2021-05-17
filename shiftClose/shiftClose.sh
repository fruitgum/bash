#!/bin/bash
if [[ $1 != 'auto' ]];then
    echo 'Bad launch!'
    exit
fi

LOGFILE="logs/shift_"$(date +%Y%m%d)".log"
. ./ini.sh
IFS=' ' read -a array <<< $(echo $(mysql -sN $localConnect -e'select DISTINCT cash_id from shiftJournal where date(date) = curdate() and code = 1'))
for CASHID in ${array[@]}; do
    POSIP=$(echo $(mysql $localConnect -e'select ip from posinfo where cash_id = '$CASHID) | awk '{print $2}')
    #BUSH=$(echo $(mysql -sN $localConnect -e'select bush from posinfo where cash_id='$CASHID''))
    FILE='shift_'$CASHID'.sh'
    touch $FILE
    chmod +x $FILE
    chown root:root $FILE
    cat copy.sh > $FILE
    ssh-keygen -R $ip > /dev/null 2>&1
    ./$FILE $CASHID $POSIP $BUSH &
    JOBID=$(echo $!)
    jobfiles+=($JOBID)
done
for job in ${jobfiles[@]}; do
    wait $job
done
