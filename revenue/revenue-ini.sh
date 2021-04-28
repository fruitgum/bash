#localDB
lHost="localhost"
lDataBase="cons"
lUser="root"
lDBPassword="WKOs6obVo"
#OuterDB
oHost="dc-pos03"
oDataBaseE="export"
oDataBaseU="ukmserver"
oUser="rUser"
oDBPassword="rUserCashRcons"
oDBPasswordB="rUserCashCons"

localConnect="-u$lUser -p$lDBPassword -D$lDataBase"
outerConnectU="-u$oUser -p$oDBPassword -D$oDataBaseU -h$oHost" 
testConnect="-u$tUser -p$tDBPassword -D$tDataBaseU -h$tHost"
