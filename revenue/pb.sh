#!/bin/bash
. ./revenue-ini.sh
localConnect="-u$lUser -p$lDBPassword -D$lDataBase"
outerConnectU="-u$oUser -p$oDBPasswordB -D$oDataBaseU"
if [[ -z S5 ]]; then
	echo "Please launch from revenue.sh"
	exit 1
else
	ldate=$2
	ldateh=$(echo $ldate | cut -d ':' -f1)
	ldatems=$(echo $ldate | cut -d ':' -f2-3)


	echo 'Stage 4 done'
	echo $(date +%T)' Launching Stage 5'
	lid=$3
	echo 'Checking receipts on bush server'
	IFS=' ' read -a bcarray <<< $(echo $(mysql -sN $localConnect -e'select cash_id from receipt_p where launch_id = '$lid' '))
	for cid in ${bcarray[@]}; do
		diff=$(echo $(mysql -uroot -pWKOs6obVo -Dcons -e'select ifnull(diff, 0) as diff from timezone where cash_id='$cid'') | cut -d ' ' -f 2)
		if { [ -z $diff ] || [ $diff = '' ]; }; then
			diff=0
		fi
		diffhm=$(echo $(mysql -uroot -pWKOs6obVo -Dcons -e'select DATE_FORMAT(time(DATE_ADD(concat(curdate(), " '$ldate'"), INTERVAL '$diff' HOUR)),"%k") as time') | cut -d ' ' -f2)
		if [[ $diffhm -lt '9' ]]; then
			diffhm='23'
		fi
		time=$diffhm':'$ldatems

		server=$(echo $(mysql $localConnect -e'select bush from posinfo where cash_id="'$cid'"' | tail -n1))
		gall=$(echo $(mysql $outerConnectU -h$server -e'
		select count(distinct(global_number)) 
		from trm_out_receipt_header
		where cash_id='$cid' and date between (concat(curdate(), " 00:00:00")) and (concat(curdate(), "'" $time"'"))
		') | cut -d ' ' -f2)
		mysql $localConnect -e"INSERT INTO receipt_b(cash_id, count, launch_id, date) VALUES ("$cid", "$gall", "$lid", now())"
	done
	echo 'Done'
	echo $(date +%T)" Comparison data between poses and bushes"
	IFS=' ' read -a carray <<< $(echo $(mysql -sN $localConnect -e'
	select DISTINCT(cash_id) as cid from pos_ukm 
	where launch_id = '$lid' 
	'))
	for ecid in ${carray[@]}; do
		read re rp <<<$(echo $(mysql -sN $localConnect -e'
	    SELECT rb.count AS ec, rp.count AS pc
		FROM receipt_b rb 
			JOIN receipt_p rp ON rb.cash_id = rp.cash_id and rb.launch_id = rp.launch_id 
			WHERE rb.launch_id = '$lid' 
			AND rp.launch_id = '$lid' 
			AND rp.cash_id = '$ecid''
            ))
		if [[ -z "$re" ]]; then
			re=0
		fi
		if [[ -z "$rp" ]]; then
			rp=0
		fi
        diff=$(($rp-$re))
        mysql $localConnect -e'insert into pos_bush values('$ecid', '$rp', '$re', '$diff', NOW(), '$lid')'
    done
	echo 'Done'
	echo 'Stage 5 Done'
	rm -f S5
fi
