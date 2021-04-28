<?php
$cstr = mysqli_connect('localhost', 'root', 'WKOs6obVo', 'cons');
$query = "SELECT p.store_name, p.number, pc.ru_name, pc.id as code, date(s.date) as date 
from shiftJournal s 
JOIN posinfo p on s.cash_id = p.cash_id 
JOIN posCodes pc on s.code=pc.id
where date(s.date) = curdate() and pc.id in (0, 10 ,12, 18) and hour(s.date) > 12";
$sql = mysqli_query($cstr, $query) or die(mysqli_error($cstr));
$down='<b>ОТЧЁТ О ЗАКРЫТЫХ СМЕНАХ</b>: '."\n";
$success = array();
$error = array();
if($sql){
    $count="SELECT count(*) as c from shiftJournal where date(date) = curdate() and code = 0";
    $countSQL=mysqli_query($cstr, $count);
    $countResult=mysqli_fetch_assoc($countSQL);
    while($row = mysqli_fetch_assoc($sql)){
        if($row['code'] == 0){
            array_push($success, array($row['store_name'],$row['number']));
        }else{
            array_push($error,array($row['store_name'],$row['number'],$row['ru_name']));
        }
    }
}

$down.="<b>Всего незакрытых смен: ".$countResult['c']."</b>\n";
$down.="<b>Закрыты успешно:</b>\n";
for($s=0; $s<count($success); $s++){
    $down.=$success[$s][0]."\t".$success[$s][1]."\t\n";
}
$down.="<b>Не закрыты из-за ошибок:</b>\n";
for($e=0; $e<count($error); $e++){
    $down.=$error[$e][0]."\t".$error[$e][1]."\t".$error[$e][2]."\t\n";
}


$to = 'e.cherkasova@modis.ru, a.brovkin@modis.ru, d.sviridov@modis.ru, regdir@modis.ru';
$msgm = str_replace(array('<i>', '</i>', '<b>', '</b>'), '', $down);
$mail = 'sendemail -f IT@modis.ru -t '.$to.' -u  Незакрытые смены предыдущего дня  -s rsmtp.modis.ru:25 -o message-charset=utf-8  -m "'.$msgm.'"';

system($mail);
$down = urlencode($down);
$cmd = 'curl'.' -s '.' -X '.'POST https://api.telegram.org/bot1378410423:AAEj8uFXmFEc3_6nBIJLbZi5WixWwlcskrw/sendMessage -d chat_id=-1001275598711 -d parse_mode="html" -d text=';
system($cmd.$down);
?>