#!/bin/bash
cdate=$(date +%d-%m-%Y)
efile='archive/revenue_log_'$cdate'.tar.gz'
afile=' revenue.log'
tar czf $efile$afile

rm -f revenue.log
