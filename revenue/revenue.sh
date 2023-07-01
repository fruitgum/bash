#!/bin/bash
. ./revenue-ini.sh
if [[ ! -e revenue.log ]]; then
	$(touch 'revenue.log')
	chmod 766 'revenue.log'
fi

if [[ $(echo $(whoami)) != 'root' ]]; then
    echo 'Only root can launch!'
    exit
fi

logDate=$(date +%d-%m-%Y' '%H:%M:%S)" "
export ldate=$(echo $(mysql $localConnect -e"SELECT DATE_FORMAT(NOW(), "%H:%i:%s %d-%m-%Y") AS now") | tail -n2)
function checkTimeLaunch {
		curDate=$(date +%s)
	if [[ $REVENUE_TIME_START -gt $(($curDate - 600)) ]];then
		echo "The last launch of script was less than 5 minutes ago. Please wait."
		exit 4
	fi
}


function manualRev {
	checkTimeLaunch
	if [[ -z $interval ]]; then
		interval='30'
		manual
	elif [[ $interval -lt '5' || $interval -gt '600' ]]; then
		echo 'Interval value must be between 5 and 600'
		exit 10
	elif [[ -e WORK ]]; then
		echo $logDate'The script is already running. If the script did not complete correctly - remove "WORK" file and run the script again'
		exit 1
	else
		manual
	fi
}

function manual {
	if [[ -e 'rmsh' ]]; then
		echo "Do not use -m and -a keys together"
		exit 8
	fi
	checkTimeLaunch
	$(touch 'rmsh')
	if [[ -z $interval ]]; then
		interval='30'
	fi
	clear
	if [[ -e 'WORK' ]]; then
		echo $logDate'The script is already running. If the script did not complete correctly - remove "WORK" file and run the script again'
		rm -f rmsh
		exit 1
	else

		$(touch 'WORK')
		x=1
		while [ $x -lt 5 ]
		do
			echo "" >> revenue.log
			x=$(( $x + 1 ))
		done

		echo $(date +%d-%m-%Y' '%H:%M:%S)' Manual launch, interval: '$interval' minutes' >> revenue.log
		tail -f revenue.log &
		./p.sh $interval >> revenue.log 2>&1
		php 'tBot/tBot.php' -- "$interval"
		tailpid=$(echo $(ps -ef | awk '$8=="tail" {print $2}'))
		kill $tailpid
		rm -f WORK
		rm -f rmsh
		exit 0
	fi
}

function helpRev {
	echo "USAGE: ./revenue.sh -[imha]"
	echo ""
	echo "For example: ./revenue -i 10 -m runnig app with 10 minutes interval with manual mode"
	echo ""
	echo "Keys:"
	echo "-i: Interval in minutes, integer from 5 to 59. Use it first, if you want to set a specefic interval! By default: 30"
	echo "-m: Manual launch. Use it if you run the app directly"
	echo "-a: Automatic launch. Use it for scheduling"
	echo "-r: send report"
	echo "-h: Help. This help"
	exit 0
}


function auto {
	if [[ -e 'rsh' ]]; then
		echo "Do not use -m and -a keys together"
		exit 8
	fi
	checkTimeLaunch
	if [[ -z $interval ]]; then
		interval='30'
	fi
	$(touch 'rsh')
	if [[ -e 'WORK' ]]; then
		echo 'The script is already running. If the script did not complete correctly - remove "WORK" file and run the script again'
		rm -f rsh
		exit 1
	else
		x=1
		while [ $x -lt 5 ]
		do
			echo "" >> revenue.log
			x=$(( $x + 1 ))
		done

		$(touch 'WORK')
		echo $(date +%d-%m-%Y' '%H:%M:%S)' Scheduled launch, interval: '$interval' minutes' >> revenue.log
		./p.sh $interval >> revenue.log 2>&1
		php 'tBot/tBot.php' -- "$interval"
		rm -f WORK
		rm -f rsh
		exit 0
	fi
}

function report {
	if [[ -e 'rmsh' || -e 'rsh' ]]; then
		echo "Do not use key -r with keys -a and/or -m"
		exit 8
	fi
	if [[ -z $interval ]]; then
		interval='30'
	fi
	if [[ -e WORK ]]; then
		echo 'The script is already running. If the script did not complete correctly - remove "WORK" file and run the script again'
		exit 1
	else
		$(touch 'WORK')
		echo $(date +%d-%m-%Y' '%H:%M:%S)' Report sent' >> revenue.log
		./count.sh $interval
		php 'tBot/tBot.php' -- "$interval"
		rm -f WORK
		exit 0
	fi
}

if [[ -n "$1" ]]; then
	while [[ -n "$1" ]]; do
		case "$1" in
			-i|--interval|i) interval="$2"
			shift ;;			
			-m|--manual|m) manualRev ;;
			-h|--help|h) helpRev ;;
			-a|--auto|a) auto ;;
			-r|--report) report 
			break ;;
			 *) helpRev ;;
		esac
		shift
	done
else
	auto
fi
