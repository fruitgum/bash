#!/bin/bash
. ./ini.sh
function finishWork(){
    echo $(date +%T)' Done' >> $LOGFILE 2>&1 
    pkill -9 tail > /dev/null 2>&1 
    rm -f shift_*.sh
    php ./report/report.php
    php ./report/myReport.php
}

clear
if [[ $(echo $(whoami)) != 'root' ]]; then
    echo 'Only root can launch!'
    exit
fi
if [[ $1 == 'auto' ]]; then
    LOGFILE="logs/shift_"$(date +%Y%m%d)".log"
    if [[ ! -e $LOGFILE ]]; then
        touch $LOGFILE
        chmod 775 $LOGFILE
    fi
    tail -f $LOGFILE &
    clear
    echo $(date +%T)' Begin'
    #DON'T FORGET TO CHANGE TABLE NAME
    IFS=' ' read -a array <<< $(echo $(mysql -sN $localConnect -e'select cash_id from posinfo where cash_id not in (1004009)')) 
    for CASHID in ${array[@]}; do
        DIFF=$(echo $(mysql -sN $outerConnectU -e"SELECT SUM((SELECT MAX(id) FROM trm_out_shift_open toso WHERE toso.cash_id = "$CASHID")-(SELECT MAX(id) FROM trm_out_shift_close tosc WHERE tosc.cash_id = "$CASHID")) as sdiff"))
        if [[ $DIFF != 0 ]]; then
            mysql $localConnect -e'insert into shiftJournal(cash_id, code, date) values('$CASHID', 1, now())'           
        fi
    done
    ./shiftClose.sh $1 >> $LOGFILE 2>&1 
    finishWork
    exit
else
    echo 'NOT FOR MANUAL USE!' && exit
fi
