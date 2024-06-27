#!/bin/bash
podLogs(){
    NS=$2

    if { [[ $2 =~ "help" ]] || [[ -z $3 || -z $2 ]]; }; then
        if [[ -z $2 ]]; then
            echo -e "${RED}Namespace is not defined${NC}"
        fi
        $1Help
    fi

    if [[ -z $3 ]]; then

        IFS=" " read -a pods <<< $(echo $(kubectl -n $NS get pods | grep -v "NAME" | awk '{print $1"@"$3"@"$4}'))

        echo "List of pods:"
        a=0
        for (( i=0; i<${#pods[@]}; i++ )); do

            pod=$(echo ${pods[i]} | cut -d"@" -f1)
            podstate=$(echo ${pods[i]} | cut -d"@" -f2)

            if [[ "${PODOK[*]}" =~ "${podstate}" ]]; then
                echo -e "   ${GREEN} [$a]: $pod${NC}" | table3
                ((a++))
                exepods+=($pod)
            elif [[ "${PODNONE[*]}" =~ "${podstate}"  ]]; then
                echo -e "   ${GRAY} [-]: $pod${NC}" | table3
            else
                echo -e "   ${RED} [$a]: $pod${NC}" | table3
                ((a++))
                exepods+=($pod)
            fi
        done

        if [[ -z $exepods ]]; then
            echo -e "\nNo pods available" && exit 1
        fi

        echo -e "\nSelect number: \c"
        read -r c
        pod=${exepods[c]}
    else
        pod=$3
    fi
    container=$(kubectl -n $NS get pod $pod -o=jsonpath={'.spec.containers[0].name'})
    echo ""
    echo -e "${YELLOW}$pod selected${NC}"
    echo ""
    kubectl -n $NS logs $pod $container
    exit 0

}

checkPods(){

    checkHelp(){
        echo "Usage: easykube check [namespase] [option] watch(optional)"
        echo "Actions:"
        echo "  all - show all state pods"
        echo "  warn - show pods with restarts"
        echo "  err - show pods with errors"
        exit 1
    }

    afterRun(){
        exepods=$@

        echo -e "\nChoose pod to view its log or press ^C: \c"
        read -r b

        if [[ -z $exepods ]]; then
            echo -e "\nNo pods available" && exit 1
        fi

        podLogs "logs" $NS ${exepods[b]}
    }

    all(){
        show(){
            a=0
            for (( i=0; i<${#pods[@]}; i++ )); do
                pod=$(echo ${pods[i]} | cut -d"@" -f1)
                podstate=$(echo ${pods[i]} | cut -d"@" -f2)
                podrestarts=$(echo ${pods[i]} | cut -d"@" -f3)
                if { [[ "${PODOK[*]}" =~ "${podstate}" && $podrestarts -gt 0 ]]; }; then
                    echo -e "   ${YELLOW} [$a]: $pod $podstate $podrestarts ${NC}" | table6
                    ((a++))
                    exepods+=($pod)
                elif [[ "${PODNONE[*]}" =~ "${podstate}"  ]]; then
                    echo -e "   ${DGRAY} [-]: $pod $podstate $podrestarts ${NC}" | table6
                    exepods+=($pod)
                elif [[ "${PODOK[*]}" =~ "${podstate}" ]];  then
                    echo -e "   ${GREEN} [$a]: $pod $podstate $podrestarts ${NC}" | table6
                    ((a++))
                    exepods+=($pod)
                else
                    echo -e "   ${RED} [$a]: $pod $podstate $podrestarts ${NC}" | table6
                    ((a++))
                    exepods+=($pod)
                fi
            done
        }

        if [[ -z $1 ]]; then
            show
            exit 0
            afterRun ${exepods[@]}
        else
            while true ; do
                tput el
                show
                if [[ -z $exepods ]]; then
                    echo -e "\nNo pods available" && exit 1
                fi
                sleep 5
            done
        fi
    }

    warn(){
        a=0
        for (( i=0; i<${#pods[@]}; i++ )); do
            pod=$(echo ${pods[i]} | cut -d"@" -f1)
            podstate=$(echo ${pods[i]} | cut -d"@" -f2)
            podrestarts=$(echo ${pods[i]} | cut -d"@" -f3)
            if { [[ "${PODOK[*]}" =~ "${podstate}" && $podrestarts -gt 0 ]]; }; then
                echo -e "   ${YELLOW} [$a]: $pod $podstate $podrestarts ${NC}" | table6
                ((a++))
                exepods+=($pod)
            fi
        done
        afterRun ${exepods[@]}
    }

    err(){
        a=0
        for (( i=0; i<${#pods[@]}; i++ )); do
            pod=$(echo ${pods[i]} | cut -d"@" -f1)
            podstate=$(echo ${pods[i]} | cut -d"@" -f2)
            podrestarts=$(echo ${pods[i]} | cut -d"@" -f3)
            if [[ "${PODERR[*]}" =~ "${podstate}" ]]; then
                echo -e "   ${RED}[$a]: $pod $podstate $podrestarts ${NC}" | table6
                ((a++))
                exepods+=($pod)
            fi
        done
        afterRun ${exepods[@]}
    }

    if { [[ $2 =~ "help" ]] || [[ -z $3 || -z $2 ]]; }; then
        if [[ -z $2 ]]; then
            echo -e "${RED}Namespace is not defined${NC}"
        fi
        $1Help
    fi

    NS=$2

    IFS=" " read -a pods <<< $(echo $(kubectl -n $NS get pods | grep -v "NAME" | awk '{print $1"@"$3"@"$4}'))

    while [ -n $3 ]; do
        case $3 in
            err) err $4
            ;;
            warn) warn $4
            ;;
            all) all $4
            ;;
            *) checkHelp
            ;;
        esac
    done
}