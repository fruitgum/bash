<?php
require_once('../phpver/lcstr.php');
require_once('../phpver/ocstr.php');

if($conn){
  mysqli_query($conn2, "truncate table posinfo");

  $query_str = "SELECT tops.cash_id as cid, trm_in_pos.number as num, ip, trm_in_store.name AS sn, ls.name AS name, tosc.kkm_serial_number AS kkmsn, trm_in_store.store_id as si FROM
    trm_out_pos_state tops
    JOIN trm_in_pos ON tops.cash_id = trm_in_pos.cash_id
    JOIN trm_in_store ON trm_in_pos.store_id = trm_in_store.store_id
    JOIN local_servers ls ON id = server_id
    JOIN trm_out_shift_close tosc ON tops.cash_id = tosc.cash_id
    JOIN trm_out_shift_open toso ON tops.cash_id = toso.cash_id AND tosc.id = toso.id
    WHERE date(toso.date) > DATE_ADD(CURDATE(), INTERVAL -2 MONTH) 
    GROUP BY tops.cash_id";

  $query = mysqli_query($conn, $query_str);

  while($row = mysqli_fetch_assoc($query)){
      $cid = sprintf("%s", $row['cid']);
      $num = sprintf("%s", $row['num']);
      $ip = sprintf("%s", $row['ip']);
      $sn = sprintf("%s", $row['sn']);
      $name = sprintf("%s", $row['name']);
      $kkmsn = sprintf("%s", $row['kkmsn']);
      $si = sprintf("%s", $row['si']);
      mysqli_query($conn2, "insert into posinfo values(
          '".$cid."',
          '".$num."',
          '".$ip."',
          '".$sn."',
          '".$name."',
          '".$kkmsn."',
          '".$si."'
      )");
  }
}

?>
