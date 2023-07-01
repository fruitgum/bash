<?php
ini_set('display_errors', '0');
include('../phpver/lcstr.php');
$interval = sprintf($argv[2]);

$lidq = mysqli_query($cstr, 'select max(id) as lid from launch_id');
$lid = mysqli_fetch_assoc($lidq); // $lid['lid']

$down='<b>ОТЧЁТ</b>:'."\n";
$countReceipts = mysqli_query($cstr, "select count(distinct(cash_id)) as posr
from receipt_p rp 
where rp.reason = 'UP' 
and rp.launch_id = (select max(id) from launch_id)") or die(mysqli_error($cstr));
$down.='<b>Работающих касс:</b>'."\n";
while ($countRecFetch = mysqli_fetch_assoc($countReceipts)) {
	$down .= sprintf($countRecFetch['posr']);
	$down .= "\n";
}

$countPoses = mysqli_query($cstr, "select max(value) as value from counter where launch_id = ".$lid['lid']." and server in ('poses')");
$down.='<b>Чеков на кассах:</b>'."\n";
while ($countPosFetch = mysqli_fetch_assoc($countPoses)) {
	$down .= sprintf($countPosFetch['value'])."\n";
}

$count = mysqli_query($cstr, "select server, max(value) as value from counter where launch_id = ".$lid['lid']." and server not in ('poses') and server not like '%bush%' group by server order by server desc");
$sumBushes_q = mysqli_query($cstr, "select sum(value) as bsum from counter where launch_id = ".$lid['lid']." and server = 't_bushes' ");
$down.='<b>Чеков на кустах, СГО, в экспорте:</b>'."\n";
while ($row5 = mysqli_fetch_assoc($count)) {
	$server[] = sprintf($row5['server']);
	$value[] = sprintf($row5['value']);
}

for($i=0; $i < count($server); $i++){
	$down .= $server[$i].': <b>'.$value[$i].'</b>';
	$down .= "\n";
}

$sumBushes = mysqli_fetch_assoc($sumBushes_q);
$down .= "Кусты: <b>".$sumBushes['bsum'].'</b>';
$down .= "\n";

$pdq = mysqli_query($cstr, "
select pi.number as cid, store_name, ip 
from receipt_p rp 
join posinfo pi on rp.cash_id = pi.cash_id 
where reason not like 'UP' 
and launch_id = ".$lid['lid']);
$down.='<b>Кассы OFFLINE:</b>'."\n";
while ($row = mysqli_fetch_assoc($pdq)) {
	$pdqc[] = sprintf($row['cid']);
	$down .= sprintf($row['cid']);
	$down .= ' ('.sprintf($row['ip']).') ';
	$down .= sprintf($row['store_name']);
	$down .= "\n";
}
$down .= '<i>Всего: '.count($pdqc).'</i>'."\n";

$down.='<b>Кассы с разницей между собой и Экспортом</b>'."\n";
$peq = mysqli_query($cstr, "select distinct(pe.cash_id) as cid, number, store_name, ip, diff 
from pos_export pe 
join posinfo pi on pe.cash_id = pi.cash_id 
where diff > 0 
and launch_id = ".$lid['lid']."
and pe.cash_id not in (
	select distinct(cash_id) as cid 
	from pos_ukm where diff > 0 
	and launch_id = ".$lid['lid']."
	) 
and pe.cash_id not in (
	select distinct(cash_id) as cid 
	from pos_bush pb 
	where diff > 0 
	and launch_id = ".$lid['lid']."
)");
while ($row2 = mysqli_fetch_assoc($peq)) {
	$peqc[] = sprintf($row2['cid']);
	$down .= sprintf($row2['diff']);
	$down .= ' №';
	$down .= sprintf($row2['number']);
	$down .= ' ';
	$down .= sprintf($row2['store_name']);
	$down .= ' ';
	$down .= sprintf($row2['ip']);
	$down .= "\n";
}
$down .= '<i>Всего: '.count($peqc).'</i>'."\n";
$down.='<b>Кассы с разницей между собой и СГО</b>'."\n";
$posUkm = mysqli_query($cstr, "select distinct(pu.cash_id) as cid, number, store_name, ip, diff 
from pos_ukm pu join posinfo pi on pu.cash_id = pi.cash_id 
where diff > 0 and launch_id = ".$lid['lid']."
and pu.cash_id not in (
	select distinct(pb.cash_id) as cid 
	from pos_bush pb 
	where diff > 0 
	and date > launch_id = ".$lid['lid']."
)");
while ($row3 = mysqli_fetch_assoc($posUkm)) {
	$puqc[] = sprintf($row3['cid']);
	$down .= sprintf($row3['diff']);
	$down .= ' №';
	$down .= sprintf($row3['number']);
	$down .= ' ';
	$down .= sprintf($row3['ip']);
	$down .= ' ';
	$down .= sprintf($row3['store_name']);
	$down .= "\n";
}
$down .= '<i>Всего: '.count($puqc).'</i>'."\n";

$down.='<b>Кассы с разницей между собой и кустами</b>'."\n";
$pbq = mysqli_query($cstr, "select distinct(cash_id) as cid, number store_name, ip, diff
from pos_bush pe 
join posinfo pi on pe.cash_id = pi.cash_id 
where diff > 0 
and launch_id = ".$lid['lid']."
");

while ($row4 = mysqli_fetch_assoc($pbq)) {
	$pbqc[] = sprintf($row4['cid']);
	$down .= sprintf($row4['diff']);
	$down .= ' №';
	$down .= sprintf($row4['number']);
	$down .= ' ';
	$down .= sprintf($row4['ip']);
	$down .= ' ';
	$down .= sprintf($row4['store_name']);
	$down .= "\n";
}
$down .= '<i>Всего: '.count($pbqc).'</i>'."\n";

$to = 'e.cherkasova@modis.ru, a.brovkin@modis.ru';

$msgm = str_replace(array('<i>', '</i>', '<b>', '</b>'), '', $down);
$mail = 'sendemail -f sms@null.ru -t '.$to.' -u RevenueMonitor -s rsmtp.null.ru:25 -o message-charset=utf-8  -m "'.$msgm.'"';
system($mail);
$down = urlencode($down);
$cmd = 'curl'.' -s '.' -X '.'POST https://api.telegram.org/12345/sendMessage -d chat_id=-1 -d parse_mode="html" -d text=';
system($cmd.$down);
unset($down);
mysqli_close($cstr);
?>
