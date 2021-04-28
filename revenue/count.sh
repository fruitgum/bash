#!/bin/bash
. ./revenue-ini.sh
localConnect="-u$lUser -p$lDBPassword -D$lDataBase"
lid=$(echo $(mysql $localConnect -e'select max(id) from launch_id') | cut -d ' ' -f 2)
array=(bush1 bush1_1 bush1_2 bush2_1 bush2_2 bush3_1 bush4_1 bush5_1 bush5_2)
for server in ${array[@]}; do
    count=$(echo $(mysql $localConnect -e'SELECT SUM(`count`) as sc FROM receipt_b 
    JOIN posinfo p ON p.cash_id = receipt_b.cash_id
    WHERE p.bush = "'$server'" AND launch_id = '$lid'') | cut -d ' ' -f2)
    mysql $localConnect -e'INSERT INTO '$lDataBase'.counter(server, value ,date, launch_id) values("'$server'", '$count', now(), '$lid')'
done

countp=$(echo $(mysql $localConnect -e'SELECT SUM(`count`) as sc FROM receipt_p 
WHERE launch_id = '$lid'') | cut -d ' ' -f2)

#count receipts from export
echo 'e'
counte=$(echo $(mysql $localConnect -e'SELECT SUM(`count`) as sc FROM receipt_e 
WHERE launch_id = '$lid'') | cut -d ' ' -f2)
if [[ $countp -lt $counte ]]; then
   counte=$countp
fi
mysql $localConnect -e"INSERT INTO "$lDataBase".counter(server, value ,date, launch_id) values('export', '$counte', now(), '$lid')"

#count receipts from SGO
echo 's'
countu=$(echo $(mysql $localConnect -e'SELECT SUM(`count`) as sc FROM receipt_u 
WHERE launch_id = '$lid'') | cut -d ' ' -f2)
if [[ $countp -lt $countu ]]; then
    countu=$countp
fi
mysql $localConnect -e"INSERT INTO "$lDataBase".counter(server, value ,date, launch_id) values('dc-pos03', '$countu', now(), '$lid')"

#count receipts from bushes
echo 'b'
countbq=$(echo $(mysql $localConnect -e'SELECT SUM(`count`) as sc FROM receipt_b 
WHERE launch_id = '$lid'') | cut -d ' ' -f2)
if [[ $countp -lt $countbq ]]; then
    countb=$countp
else
    countb=$countbq
fi
echo $countb
mysql $localConnect -e"INSERT INTO "$lDataBase".counter(server, value ,date, launch_id) values('t_bushes', '$countb', now(), '$lid')"

#count receipts from poses
echo 'p'
mysql $localConnect -e'
insert into counter(value, server, date, launch_id) 
(select ifnull(sum(rp.count), 0), "poses", now(), launch_id
from receipt_p rp where launch_id = '$lid' and reason="UP")'
