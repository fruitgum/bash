<?php 
include 'lcsrt.php';
include 'ocstr.php';

$cidq = mysqli_query($lc, 'select DISTINCT(cash_id) as cid from receipt_p where reason = "UP" and date between date_add(now(), interval -15 minute) and now()');
while ($cidr = mysqli_fetch_assoc($cidq)) {
	$cid = sprintf("%s", $cidr['cash_id']);
	mysqli_query($lc, "INSERT INTO pos_export (
		SELECT a.ci, a.pc, a.ec, SUM(a.pc - a.ec), NOW() 
			FROM (
	    		SELECT rp.cash_id AS ci, re.count AS ec, rp.count AS pc, re.date 
	    		FROM receipt_e re 
				JOIN receipt_p rp ON re.cash_id = rp.cash_id 
				WHERE re.id = (select max(id) from receipt_e re2 where re2.cash_id = '".$cid."' and date(re2.date) = curdate()) 
				AND rp.id = (select max(id) from receipt_p rp2 where rp2.cash_id = '".$cid."' and date(rp2.date) = curdate()) 
				AND rp.cash_id = '".$cid."'
	  		)
	  	AS a)");
}
/*
$ciddq = mysqli_query($lc, 'select rp.cash_id as cid, bush from receipt_p rp join posinfo pi on rp.cash_id = pi.cash_id where reason not like "UP" and date > date_add(now(), interval -15 minute)')
echo 'State DOWN:'
while ($ciddr = mysql_fetch_assoc($ciddq)) {
	$cid = sprintf("%s", $ciddr['cash_id']);
	$bush = sprintf("%s", $ciddr['bush']);
	echo $cid.' '.$bush;
}
*/

 ?>