#localDB
lHost="localhost"
lDataBase="cons"
lUser="root"
lDBPassword="WKOs6obVo"
#OuterDB
oHost="dc-pos03"
oDataBaseU="ukmserver"
oUser="rUser"
oDBPassword="rUserCashRcons"
#testOuterDb
tHost="sgo-prod"
tDataBaseU="ukmserver"
tUser="rUser"
tDBPassword="rUserCashRcons"

localConnect="-u$lUser -p$lDBPassword -D$lDataBase"
outerConnectU="-u$oUser -p$oDBPassword -D$oDataBaseU -h$oHost" 
testConnect="-u$tUser -p$tDBPassword -D$tDataBaseU -h$tHost"
