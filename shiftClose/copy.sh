#!/bin/bash
. ./ini.sh
POSONLINE=0 #Check for online; exit 10
POSDB=0 #Check for DB state; exit 11
ISSHIFTOPEN=0 #Check for opened shift; exit 12
POSUKM=0 #Check for client state; exit 13
ISRECEIPTOPEN=0 #Check for opened receipt; exit 14
ISLOGOUT=0 #check for auth on pos; exit 15
ISMONEY=0 #Check for money in cashbox; exit 16
CHECKSCORE=0

CASHID=$1
POSIP=$2
BUSH=$3

POSUSER='root'
POSPASS=''
POSDBPASS=''
SSHTIMEOUT=30
POSAUTH="sshpass -p "$POSPASS" ssh -q "$POSUSER"@"$POSIP" -o ConnectTimeout="$SSHTIMEOUT" "
POSDBAUTH=' -u'$POSUSER' -Dukmclient -p'$POSDBPASS

$POSAUTH' mysql'$POSDBAUTH' -e"update trm_auth_local_storage set deleted=1, version=0 where user=9999"' 

function err(){
    case $* in
        0) code=$*' (successfull)'
            ;;
        1) code='1 (Shift is open)'
            ;; 
        10) code=$*" (Pos is unreachable)"
            ;;
        11) code=$*" (DB is unreachable)"
            ;;
        12) code=$*" (ukmclient error. Check POS logs for more info)"
            ;;
        13) code=$*" (Shift already closed)"
            ;;
        17) code=$*" (POS has an open receipt)"
            ;;
        18) code=$*" (Failed to close shift)"
            ;;
        20) code=$*" (Failed to create tals)"
            ;;
        *) code='-1 (undefined error: '$CHECKSCORE')'
    esac
    mysql $localConnect -e'update shiftJournal set code='$*' where cash_id = '$CASHID''
    echo $(date +%T)' '$CASHID'   '$code
    exit 0
}

function checkPos(){
    echo $(date +%T)' '$CASHID  ' Ping...'
    CHECKPOS=$(echo $($POSAUTH 'echo 1'))
    if [[ $CHECKPOS -eq 1 ]]; then
        POSONLINE=1
        CHECKSCORE=$(($CHECKSCORE+1))
        echo $(date +%T)' '$CASHID  ' Ping OK'
    else
        POSONLINE=0
        err 10
    fi
}

checkPos

function dbCheck(){
    echo $(date +%T)' '$CASHID  ' Checking DB'
    DBCHECK=$(echo $($POSAUTH 'mysql -sN'$POSDBAUTH' -e"select 1 from trm_in_pos"' 2>&1 ))
    if [[ $DBCHECK -eq '1' ]]; then
        POSDB=1
        CHECKSCORE=$(($CHECKSCORE+1))
        echo $(date +%T)' '$CASHID  ' DB OK'
    else
        POSDB=0
        err 11
    fi
}

dbCheck


function shiftCheck(){
    echo $(date +%T)' '$CASHID'   ISMONEY: '$ISMONEY
    if [[ $ISMONEY -eq 0 ]]; then
        echo $(date +%T)' '$CASHID  ' Checking for opened shift'
    else
        echo $(date +%T)' '$CASHID  ' Checking that shift was closed correctly'
    fi
    OPENID=$(echo $($POSAUTH 'mysql -sN'$POSDBAUTH' -e"select max(id) as id from trm_out_shift_open"'))
    CLOSEID=$(echo $($POSAUTH 'mysql -sN'$POSDBAUTH' -e"select max(id) as id from trm_out_shift_close"'))
    #NAME=$(echo $($POSAUTH 'mysql -sN'$POSDBAUTH' -e"select user_name from trm_out_shift_open so join trm_out_login l on so.login=l.id where so.id="'$OPENID'"'))
    if { [[ $OPENID -eq $CLOSEID ]] && [[ $ISMONEY -eq 0 ]]; }; then
        err 13
    elif { [[ $OPENID -eq $CLOSEID ]] && [[ $ISMONEY -gt 0 ]]; }; then
        curl -d 'selection=["'"$CASHID"'"]&_'$(date +%s) -d 'message=Смена+была+закрыта+автоматически. Не+забудьте+выполнить+изъятие+и+сверку+итогов+перед+началом+работы' http://dc-pos03/ukm/index.php?r=pos/sendMessage -b PHPSESSID=1 > /dev/null 2>&1
        echo $(date +%T)' '$CASHID  ' Shift number '$CLOSEID' was closed'
        #$POSAUTH' mysql'$POSDBAUTH' -e"drop table tals"'
        err 0
    elif { [[ $OPENID -gt $CLOSEID ]] && [[ $ISMONEY -gt 0 ]]; }; then
        err 18
    else
        ISSHIFTOPEN=0
        CHECKSCORE=$(($CHECKSCORE+1))
        echo $(date +%T)' '$CASHID  ' Shift is open'
    fi
}

shiftCheck

rCounter=0
function checkReceipt(){
    if [[ $rCounter -eq 3 ]]; then
        err 17
    else
        echo $(date +%T)' '$CASHID  ' Checking for unclosed receipt'
        RECEIPTHEAD=$(echo $($POSAUTH' mysql'$POSDBAUTH' -e"select max(id) as id from trm_out_receipt_header where global_number=(select max(global_number) from trm_out_receipt_header)"') | awk '{print $2}')
        RECEIPTFOOT=$(echo $($POSAUTH' mysql'$POSDBAUTH' -e"select max(id) as id from trm_out_receipt_footer where id="'$RECEIPTHEAD'') | awk '{print $2}')
        if [[ $RECEIPTHEAD -eq $RECEIPTFOOT ]]; then
            ISRECEIPTCLOSE=1
            CHECKSCORE=$(($CHECKSCORE+1))
            echo $(date +%T)' '$CASHID  ' All receipts are closed'
        else
            echo $(date +%T)' '$CASHID  ' Receipt found'
            $POSAUTH' mysql'$POSDBAUTH' -e"insert into trm_out_receipt_footer values("'"$CASHID"'", "'"$RECEIPTHEAD"'", 1, now(), 0, 0, 0)"'
            echo $(date +%T)' '$CASHID  ' Restarting UKM...'
            $POSAUTH "/etc/init.d/ukmclient restart"
            rCounter=$(($rCounter+1))
            echo $(date +%T)' '$CASHID  ' Sleep 30 seconds to make sure ukmclient has been restarted'
            sleep 30
            checkReceipt
            ISLOGIN=1
        fi
    fi
}
checkReceipt

function ukmCheck(){
UKMCHECK=$(echo $($POSAUTH" ps -a | grep ukmclient | awk '{print $1}'"))
UKMLOGFILE="/usr/local/ukmclient/logs/"$(date +%Y)"/"$(date +%m)"/"$(date +%Y-%m-%d)".log"
LOGCHECK=$(echo $($POSAUTH" tail -n 20 "$UKMLOGFILE" | grep 'FATAL' | head -n1"))
if [[ $UKMCHECK ]]; then
    if [[ $LOGCHECK ]]; then
        echo $LOGCHECK
        POSUKM=0
        err 12
    else
        POSUKM=1
        CHECKSCORE=$(($CHECKSCORE+1))
        echo $(date +%T)' '$CASHID  ' UKM started successfully'
    fi
    sleep 10
else
    echo $LOGCHECK
    POSUKM=0
    err 12
fi
}

function client(){
    if [[ $ISLOGIN -eq 0 ]]; then
        LOGIN=$(echo $($POSAUTH' mysql -sN'$POSDBAUTH' -e"select max(id) from trm_out_login"'))
        echo $(date +%T)' '$CASHID  ' Restarting UKM...'
        $POSAUTH "/etc/init.d/ukmclient restart"
        echo $(date +%T)' '$CASHID  ' Sleep 30 seconds to make sure ukmclient has been restarted'
        sleep 30
        ISLOGOUT=1
        ukmCheck
    else
        ukmCheck
    fi
}
client

function cash(){
    t=0
    echo $(date +%T)' '$CASHID  ' Search for money in cashbox'
    USERID=$(echo $($POSAUTH' mysql -sN'$POSDBAUTH' -e"select min(user) from trm_auth_local_storage where deleted=0"'))
    MONEYCHECK=$(echo $($POSAUTH' mysql'$POSDBAUTH' -e"select ifnull((select sum(amount) from trm_auth_local_storage where deleted=0), 0) as amount "') | awk '{print $2}')
    AMOUNTINT=$(echo $MONEYCHECK | cut -d '.' -f1)
    AMOUNTDECI=$(echo $MONEYCHECK | cut -d '.' -f2)
    if { [[ $AMOUNTDECI -eq 0 ]] && [[ $AMOUNTINT -eq 0 ]]; }; then
        ISMONEY=1
        echo $(date +%T)' '$CASHID  ' Cashbox is empty'
    elif { [[ $AMOUNTDECI -gt 0 ]] || [[ $AMOUNTINT -gt 0 ]]; }; then
        NMONEY='-'$MONEYCHECK
        ISMONEY=2
        echo $(date +%T)' '$CASHID  ' Cashbox is not empty. Total: '$MONEYCHECK
    fi
    CHECKSCORE=$(($CHECKSCORE+1))
}

if [[ $CHECKSCORE == 5 ]]; then
    cash
fi

if [[ $CHECKSCORE == 6 ]]; then
    curl -d 'selection=["'"$CASHID"'"]&_'$(date +%s) http://host/ukm/index.php?r=pos/closeShift -b PHPSESSID=1 > /dev/null 2>&1
    sleep 60
    if [[ $ISMONEY -eq 2 ]]; then
        $POSAUTH' mysql'$POSDBAUTH' -e"insert into trm_auth_local_storage select * from tals"'
        ISMONEY=3
    fi
    shiftCheck
else
    err -1
fi



