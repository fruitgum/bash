#!/bin/bash
if ! { [ -e rmsh ] || [ -e rsh ]; }; then
	echo "Please launch from revenue.sh"
	exit 1
else
	. ./revenue-ini.sh
	localConnect="-u$lUser -p$lDBPassword -D$lDataBase"
	outerConnectU="-u$oUser -p$oDBPassword -D$oDataBaseU"
	outerConnectE="-u$oUser -p$oDBPassword -D$oDataBaseE -h$oHost"
	touch S1
	echo "Launching Stage 1"
   	getDate=$(echo $(mysql $localConnect -e'select date_format(date_add(now(), interval -'$1' minute), "%Y-%m-%d %H:%i:%s") as df') | cut -d ' ' -f2-3)
	launchDate=$(echo $getDate | cut -d ' ' -f2)
	date=$(echo $getDate | cut -d ' ' -f1)
	echo $launchDate
	$(mysql $localConnect -e'insert into launch_id(date) values(now())')
	echo "Creating temporary files"
	echo "Collect data from poses"
	lid=$(echo $(mysql $localConnect -e'select max(id) from launch_id') | cut -d ' ' -f 2)
	IFS=' ' read -a qiarray <<< $(echo $(mysql $localConnect -e'select ip as ipad from posinfo where cash_id not like "1004%"'))
	iarray=${qiarray[@]/"ipad"}
	for ip in ${iarray[@]}; do
		cid=$(echo $(mysql $localConnect -e'select cash_id from posinfo where ip="'$ip'"' | tail -n 1))
		ff='cid_rev_'$cid'.sh'
		file=$(pwd)'/'$ff
		touch $file
		chown root:root $file
		chmod 0775 $file
		ssh-keygen -R $ip > /dev/null 2>&1
		cat copy.sh > $file
        ./cid_rev_$cid.sh $1 $cid $ip $lid $launchDate $date & 2>/dev/null
		JOBID=$(echo $!)
    	jobfiles+=($JOBID)
	done
	for job in ${jobfiles[@]}; do
		wait $job
	done
	echo "Stage 1 done"
	rm -f S1
    touch S2
    ./pe.sh $1 $launchDate $lid >> revenue.log 2>&1
fi