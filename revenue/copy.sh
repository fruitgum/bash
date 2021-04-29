#!/bin/bash
. ./revenue-ini.sh
CHECKSCORE=0

interval=$1
CASHID=$2
POSIP=$3
lid=$4
ldate=$5
date=$6
SSHTIMEOUT=30
POSAUTH="sshpass -p "$POSPASS" ssh -q "$POSUSER"@"$POSIP" -o ConnectTimeout="$SSHTIMEOUT" "
POSDBAUTH=' -u'$POSUSER' -Dukmclient -p'$POSDBPASS

function err(){
    case $1 in
        0) code="UP"
            ;;
        10) code="PING"
            ;;
        11) code="NODB"
            ;;
        *) code='UNDEF'
    esac
    #echo 'The running script finished with code: '$code
    mysql $localConnect -e'INSERT INTO receipt_p(cash_id, count, date, reason, launch_id) values ('$CASHID', '$2', now(), "'$code'", '$lid')'
    #echo $(date +%T)' '$CASHID' '$code' '$2
    exit 0
}

function checkPos(){
    #echo $(date +%T)' '$CASHID  ' Ping...'
    CHECKPOS=$(echo $($POSAUTH 'echo 1'))
    if [[ $CHECKPOS -eq 1 ]]; then
        CHECKSCORE=$(($CHECKSCORE+1))
        #echo $(date +%T)' '$CASHID  ' Ping OK'
    else
        err 10 0
    fi
}

function dbCheck(){
    #echo $(date +%T)' '$CASHID  ' Checking DB'
    DBCHECK=$(echo $($POSAUTH 'mysql'$POSDBAUTH' -e"select 1 from trm_in_pos"' 2>&1 | grep -v "FATAL"  | grep -v "Warning" | grep -v "Usage" )  | awk '{print $2}')
    if [[ $DBCHECK -eq '1' ]]; then
		DB=$(echo $($POSAUTH 'if [[ -e /usr/local/lillo ]]; then echo 'lillo'; else echo 'ukmclient'; fi'))
        CHECKSCORE=$(($CHECKSCORE+1))
        #echo $(date +%T)' '$CASHID  ' DB OK'
    else
        err 11 0
    fi
}

checkPos
dbCheck

if [[ $CHECKSCORE == 2 ]]; then
	ldateh=$(echo $ldate | awk -F ":" '{print $1}')
	ldatems=$(echo $ldate | awk -F ":" '{print $2":"$3}')
	diff=$(echo $(mysql $localConnect -e'select ifnull(diff, 0) as diff from timezone where cash_id='$CASHID'') | awk '{print $2}')

	if { [ -z $diff ] || [ $diff = '' ]; }; then
		diff=0
	fi

	diffhm=$(echo $(mysql $localConnect -e'select DATE_FORMAT(time(DATE_ADD(concat(curdate(), " '$ldate'"), INTERVAL '$diff' HOUR)),"%k") as time') | awk '{print $2}')

	if [[ $diffhm -lt '9' ]]; then
		diffhm='23'
	fi

	time=$diffhm':'$ldatems

    query='select count(distinct(global_number)) as c from trm_out_receipt_header where date between (concat("'$date'", " 00:00:00")) and (concat("'$date'", "'" $time"'"))'
    sum=$(echo $($POSAUTH' mysql'$POSDBAUTH' -D'$DB' -e'"'$query'"'')  | grep -v "Warning" | grep -v "Usage" | awk '{print $2}')
	err 0 $sum
fi
