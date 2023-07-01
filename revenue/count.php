<?php
require('phpver/lcstr.php');
$bush=array('bush1', 'bush1_1', 'bush1_2', 'bush2_1', 'bush2_2', 'bush3_1', 'bush4_1', 'bush5_1', 'bush5_2');
$lidQ=mysqli_query($lc, "select max(id) as lid from launch_id");
$lid=mysqli_fetch_assoc($lidQ);
print_r($lid);
$i=0;
while($i<count($bush)){
    $countQ=mysqli_query($lc, "SELECT SUM(`count`) as sc FROM receipt_b 
    JOIN posinfo p ON p.cash_id = receipt_b.cash_id
    WHERE p.bush = '".$bush[$i]."' AND launch_id = '".$lid['lid']."'");
    $count=mysqli_fetch_assoc($countQ);
    if($count['sc'] == ''){
        $count['cs'] = 0;
    }
    mysqli_query($lc, "INSERT INTO ".$lDB.".counter(server, value ,date, launch_id) values('".$bush[$i]."', ".$count['sc'].", now(), ".$lid['lid'].")");
    $i++;
}

$countpQ=mysqli_query($lc, "SELECT SUM(`count`) as sc FROM receipt_p WHERE reason='UP' AND launch_id = ".$lid['lid']);
$countp=mysqli_fetch_assoc($countpQ);
mysqli_query($lc, "INSERT INTO ".$lDB.".counter(server, value ,date, launch_id) values('poses', ".$countp['sc'].", now(), ".$lid['lid'].")");


$counteQ=mysqli_query($lc, "SELECT SUM(`count`) as sc FROM receipt_e WHERE launch_id = ".$lid['lid']);
$counte=mysqli_fetch_assoc($counteQ);
if($counte['sc'] > $countp['sc']){
    $countre = $countp['sc'];
}else{
    $countre = $counte['sc'];
}
mysqli_query($lc, "INSERT INTO ".$lDB.".counter(server, value ,date, launch_id) values('export', ".$countre.", now(), ".$lid['lid'].")");

$countuQ=mysqli_query($lc, "SELECT SUM(`count`) as sc FROM receipt_u WHERE launch_id = ".$lid['lid']);
$countu=mysqli_fetch_assoc($countuQ);
if($countu['sc'] > $countp['sc']){
    $countue = $countp['sc'];
}else{
    $countue = $countu['sc'];
}
mysqli_query($lc, "INSERT INTO ".$lDB.".counter(server, value ,date, launch_id) values('sgo', ".$countue.", now(), ".$lid['lid'].")");

// $countbQ=mysqli_query($lc, "SELECT SUM(`count`) as sc FROM receipt_b WHERE launch_id = ".$lid['lid']);
$countbQ=mysqli_query($lc, "SELECT SUM(`value`) as sc from counter where server like 'bush%'");
$countb=mysqli_fetch_assoc($countbQ);
if($countb['sc'] > $countp['sc']){
    $countbe = $countp['sc'];
}else{
    $countbe = $countb['sc'];
}
mysqli_query($lc, "INSERT INTO ".$lDB.".counter(server, value ,date, launch_id) values('t_bushes', ".$countbe.", now(), ".$lid['lid'].")");

$countPRQ=mysqli_query($lc, "SELECT COUNT(DISTINCT (cash_id)) as cid from receipt_p p where date(date) = curdate() and p.count > 0");
$countPR=mysqli_fetch_assoc($countPRQ);
mysqli_query($lc, "INSERT INTO ".$lDB.".counter(server, value, date, launch_id) values('pos_wreceipt', ".$countPR['cid'].", now(), ".$lid['lid'].")");
