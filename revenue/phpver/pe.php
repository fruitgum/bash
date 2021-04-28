<?php 
include 'lcsrt.php';
include 'ocstr.php';

$cidq = mysqli_query($ls, 'select cash_id from posinfo');
while ($cidr = mysqli_fetch_assoc($cidq)) {
	$cid = sprintf("%s", $cidr['cash_id']);
	$esumm = mysqli_query($sgoe, 'select count(*) from receipt where date(date) between (SELECT (CONCAT(curdate(), "00:00:00"))) and date_add(now(), interval -5 minute) and cash_id="'.$cid.'"');
	mysqli_query($lc, "INSERT INTO receipt_e(cash_id, count, date) VALUES (".$ncid.", ".$gall.", now())");
}


 ?>