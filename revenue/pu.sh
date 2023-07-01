#!/bin/bash
if [[ -z S4 ]]; then
	echo "Please launch from revenue.sh"
	exit 1
else
	ldate=$2
	ldateh=$(echo $ldate | cut -d ':' -f1)
	ldatems=$(echo $ldate | cut -d ':' -f2-3)
	. ./revenue-ini.sh
	localConnect="-u$lUser -p$lDBPassword -D$lDataBase"
	outerConnectU="-u$oUser -p$oDBPassword -D$oDataBaseU -h$oHost"
	echo $(date +%T)' Launching Stage 4'
	lid=$3
	echo 'Checking receipts on ukmserver'
	IFS=' ' read -a uarray <<< $(echo $(mysql -sN $localConnect -e'select distinct(cash_id) as cid from receipt_p where launch_id = '$lid''))
	for cid in ${uarray[@]}; do
		diff=$(echo $(mysql -sN $localConnect -e'select ifnull(diff, 0) as diff from timezone where cash_id='$cid''))
		if { [ -z $diff ] || [ $diff = '' ]; }; then
			diff=0
		fi
		diffhm=$(echo $(mysql -sN $localConnect -e'select DATE_FORMAT(time(DATE_ADD(concat(curdate(), " '$ldate'"), INTERVAL '$diff' HOUR)),"%k") as time'))
		if [[ $diffhm -lt '9' ]]; then
			diffhm='23'
		fi
		time=$diffhm':'$ldatems

		gall=$(echo $(mysql -sN $outerConnectU -e'
		select count(distinct(global_number)) 
		from trm_out_receipt_header
		where cash_id='$cid' and date between (concat(curdate(), " 00:00:00")) and (concat(curdate(), "'" $time"'"))
		'))
		mysql $localConnect -e'INSERT INTO receipt_u(cash_id, count, launch_id, date) VALUES ('$cid', '$gall', '$lid',  now())'
	done
	echo "Done"
	echo $(date +%T)" Comparison data between poses and ukmserver"
	IFS=' ' read -a carray <<< $(echo $(mysql -sN $localConnect -e'
	select DISTINCT(cash_id) as cid from pos_export 
	where launch_id = '$lid' 
	'))
	for cid in ${carray[@]}; do
		read re rp <<< $(echo $(mysql -sN $localConnect -e'
	    SELECT ru.count AS ec, rp.count AS pc
		FROM receipt_u ru 
			JOIN receipt_p rp ON ru.cash_id = rp.cash_id and ru.launch_id = rp.launch_id 
			WHERE ru.launch_id = '$lid' 
			AND rp.launch_id = '$lid' 
			AND rp.cash_id = '$cid''
            ) | grep -v "ERROR")
		if [[ -z "$re" ]]; then
			re=0
		fi
		if [[ -z "$rp" ]]; then
			rp=0
		fi
        diff=$(($rp-$re))
		if [[ $diff != 0 ]]; then
        	mysql $localConnect -e'insert into pos_ukm values('$cid', '$rp', '$re', '$diff', NOW(), '$lid')'
		fi
    done
	echo 'done'
	rm -f S4
	touch S5
	./pb.sh $1 $ldate $lid >> revenue.log 2>&1
	echo 'Done'
fi

