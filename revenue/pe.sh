#!/bin/bash
if [[ -z S2 ]]; then
	echo "Please launch from revenue.sh"
	exit 1
else
	. ./revenue-ini.sh
	localConnect="-u$lUser -p$lDBPassword -D$lDataBase"
	outerConnectU="-u$oUser -p$oDBPassword -D$oDataBaseU"
	outerConnectE="-u$oUser -p$oDBPassword -D$oDataBaseE -h$oHost"

	ldate=$2
	ldateh=$(echo $ldate | cut -d ':' -f1)
	ldatems=$(echo $ldate | cut -d ':' -f2-3)

	lid=$3

	echo "Launching Stage 2"
	echo $2
	echo "Collect data from export DB"
	IFS=' ' read -a narray <<< $(echo $(mysql -sN $localConnect -e'select distinct(cash_id) as ipad from receipt_p where launch_id = '$lid' and reason = "UP"'))

	for ncid in ${narray[@]}; do
		diff=$(echo $(mysql -uroot -pWKOs6obVo -Dcons -e'select ifnull(diff, 0) as diff from timezone where cash_id='$ncid'') | cut -d ' ' -f 2)
		if { [ -z $diff ] || [ $diff = '' ]; }; then
			diff=0
		fi
		diffhm=$(echo $(mysql -uroot -pWKOs6obVo -Dcons -e'select DATE_FORMAT(time(DATE_ADD(concat(curdate(), " '$ldate'"), INTERVAL '$diff' HOUR)),"%k") as time') | cut -d ' ' -f2)
		if [[ $diffhm -lt '9' ]]; then
			diffhm='23'
		fi
		time=$diffhm':'$ldatems		
		gall=$(echo $(mysql -sN $outerConnectE -e'
		select count(distinct(global_number)) 
		from receipt
		where cash_id='$ncid' and date between (concat(curdate(), " 00:00:00")) and (concat(curdate(), "'" $time"'"))
		'))
		mysql $localConnect -e"INSERT INTO receipt_e(cash_id, count, launch_id, date) VALUES ("$ncid", "$gall", "$lid", now())"
	done
	echo 'Removing temporary files'
	rm -f cid_rev_*.sh
	echo "Stage 2 done"
	rm -f S2
	touch S3
	echo $(date +%T)" Launching Stage 3"
	echo "Comparison data between poses and export"
	IFS=' ' read -a carray <<< $(echo $(mysql -sN $localConnect -e'
	select DISTINCT(cash_id) as cid from receipt_p 
	where reason = "UP" 
	and launch_id = '$lid' 
	'))
	for ecid in ${carray[@]}; do
		read re rp <<< $(echo $(mysql -sN $localConnect -e'
	    SELECT re.count AS ec, rp.count AS pc
		FROM receipt_e re 
			JOIN receipt_p rp ON re.cash_id = rp.cash_id and re.launch_id = rp.launch_id 
			WHERE re.launch_id = '$lid' 
			AND rp.launch_id = '$lid' 
			AND rp.cash_id = '$ecid''
            ))
        diff=$(($rp-$re))
		if [[ $diff != 0 ]]; then
        	mysql $localConnect -e'insert into pos_export values('$ecid', '$rp', '$re', '$diff', NOW(), '$lid')'
		fi
    done

	echo $(date +%T)" Stage 3 done"
	echo 'Pos with diff between itself and export'
	IFS=' ' read -a dearray <<< $(echo $(mysql $localConnect -e'
	select cash_id as cid 
	from pos_export 
	where launch_id = '$lid' and diff > 0'))
	dear=${dearray[@]/"cid"}
	rm -f S3
	touch 'S4'
	./pu.sh $1 $ldate $lid >> revenue.log 2>&1
fi
php 'count.php'
mysql $localConnect -e'update launch_id set finish_date=now() where id = '$lid''
echo $(date +%d-%m-%Y' '%H:%M:%S)" Work finished"