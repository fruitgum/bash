#!/bin/bash
dbPass(){
    #in future - make a json map for secrets
    dbHelp(){
        echo "Usage:
    easykube db [namespace] [action]"
        echo "Actions:
    pass - show db password
    connect - connect to db
    dump - make db dump"
        exit 1
    }

    showDbPass(){
        echo -e "${YELLOW}$NS DB PASSWORD:${NC}"
        echo $DBPASS
        exit 0
    }

    if { [[ $2 =~ "help" ]] || [[ -z $3 || -z $2 ]]; }; then
        if [[ -z $2 ]]; then
            echo -e "${RED}Namespace is not defined${NC}"
        fi
        $1Help
    fi

    NS=$2
    kubectl describe ns $NS > /dev/null || exit 1
    #DBPASS=$(kubectl -n $NS get secret db-postgresql -o=jsonpath='{.data.postgresql-password}' | base64 -d || echo "Could not find secret" && exit 1)
    IFS=" " read -a dbPassSecret <<< $(echo $(kubectl -n $NS get pod db-postgresql-0 -o json | jq -r '.spec.containers | .[0].env | .[] | select(.name=="POSTGRES_PASSWORD") | .valueFrom.secretKeyRef | .key, .name'))
    DBPASS=$(kubectl -n $NS get secret ${dbPassSecret[1]} -o json | jq '.data."'${dbPassSecret[0]}'"' -r | base64 -d || echo "Could not find secret" && exit 1)
    DB=$4

    case $3 in
        connect) dbConnect $NS $DBPASS
        ;;
        dump) dbDump $NS $DBPASS $DB
        ;;
        pass) showDbPass
        ;;
        restore) dbRestore $NS $DBPASS $DB
        ;;
        *) echo "Unknow action" && dbHelp && exit 1
        ;;
    esac

}

dbConnect(){

    NS=$1
    DBPASS=$2
    choosePod(){
        pods=$@
        echo "Select DB pod"
        for (( i=0; i<${#pods[@]}; i++ )); do
            echo "[$i]: ${pods[i]}"
        done
        read -r c
        podDb=${pods[c]}
    }

    IFS=" " read -a pods <<< $(echo $(kubectl -n $NS get pods -l app.kubernetes.io/instance=db | grep -v "NAME" | cut -d' ' -f1))
    case ${#pods[@]} in
        0) echo "No pods found" && exit 1
        ;;
        1) podDb=${pods[0]}
        ;;
        *) choosePod ${pods[@]}
        ;;
    esac

    if [[ -z $podDb ]]; then
        choosePod ${pods[@]}
    fi
    container=$(kubectl -n $NS get pod $podDb -o=jsonpath={'.spec.containers[0].name'})
    kubectl -n $NS exec -it $podDb -c $container -- sh -c "PGPASSWORD=$DBPASS psql -U postgres"
}

dbData(){
    #Pod name 
    pvc=$(kubectl -n $NS get pod db-postgresql-0 -o json | jq '.spec.volumes | .[0].persistentVolumeClaim.claimName' -r)
    IFS=" " read -a owner <<< $(echo $(kubectl -n $NS get pod db-postgresql-0 -o json | jq -r '.metadata.ownerReferences | .[] | .kind, .name'))
    kind=${owner[0]}
    kindName=${owner[1]}

}

dbDump(){
    NS=$1
    DBPASS=$2

    if [[ -z $3 ]]; then
        DB=$NS
    else
        DB=$3
    fi

    choosePod(){
        pods=$@
        echo "Select DB pod"
        for (( i=0; i<${#pods[@]}; i++ )); do
            echo "[$i]: ${pods[i]}"
        done
        read -r c
        podDb=${pods[c]}
    }

    IFS=" " read -a pods <<< $(echo $(kubectl -n $NS get pods -l app.kubernetes.io/instance=db | grep -v "NAME" | cut -d' ' -f1))
    case ${#pods[@]} in
        0) echo "No pods found" && exit 1
        ;;
        1) podDb=${pods[0]}
        ;;
        *) choosePod ${pods[@]}
        ;;
    esac

    if [[ -z $podDb ]]; then
        choosePod ${pods[@]}
    fi

    echo -e "Enter dir where dump will be placed. Example: /tmp. Default is current directory: \c"
    read -r dumpdir
    if [[ -z $dumpdir ]]; then
        dumpdir="./"
    fi

    if [[ dumpdir == "~" ]]; then
        if [[ $USER == 'root' ]]; then
            dumpdir="/root"
        else
            dumpdir="/home/$USER"
        fi
    fi

    FILE=$dumpdir"/"$NS.$(date +%d"."%m"."%Y).sql.gz
    container=$(kubectl -n $NS get pod $podDb -o=jsonpath={'.spec.containers[0].name'})
    echo -e "${BLUE}Dumping DB $NS into $FILE ${NC}"
    kubectl -n $NS exec $podDb -c $container -- sh -c "PGPASSWORD=$DBPASS pg_dump -U postgres -Z 9 $DB" > $FILE
    echo "Done"

}

dbRestore(){
    #kubectl -n $NS sca
    #kubectl -n $NS get pod db-postgresql-0 -o json | jq ".spec.volumes [0].persistentVolumeClaim.claimName " -r

    NS=$1
    DBPASS=$2
    DB=$3

    if [[ -z $3 ]]; then
        DB=$NS
    else
        DB=$3
    fi

    dbRestoreHelp(){
        echo "Usage:
                easykube db [namespace] restore"
        echo "Supported file formats: sql, sql.gz"
        exit 1
    }

    echo -e "${RED}ATTENTION!"
    echo -e "${RED}DB storage will be deleted. This action cannot be undone!\n"
    echo -e "${YELLOW}Confirm the operation by typing the database name:${NC} \c"
    read -r commit
    if [[ $commit = $DB ]]; then
        #steps:
        #kill instance - kubectl -n $NS scale statefulset db-postgresql --replicas 0
        #delete pvc - kubectl -n $KN delete pvc db-postgresql
        #run instance - kubectl -n $NS scale statefulset db-postgresql --replicas 1
        #wait for ready - kubectl -n $NS wait --for=condition=ready pod -l app.kubernetes.io/instance=db
        #restore - (zless || zcat) $FILE | kubectl -n $NS exec $podDb -c $container -- sh -c "PGPASSWORD=$DBPASS psql -U postgres $DB"
        echo -e "\n${YELLOW}DB dump file location (ex. dump.sql, /tmp/dump.sql.gz): ${NC}\c"
        read -r FILE
        ext=$(echo $FILE | rev | cut -d. -f1 | rev)
    else
        echo "Aborted" && exit 0
    fi

    compressed(){
        gzip -t $FILE
        if [[ $? -ne 0 ]]; then
            echo "${RED} Archive corrupted" && exit 1
        fi
        echo -e "${GREEN}File is OK"
        echo -e "${BLUE}Shuting down instance${NC}"
        kubectl -n $NS scale statefulset -l app.kubernetes.io/name=postgresql --replicas 0
        sleep 30
        echo -e "${BLUE}Deleting pvc${NC}"
        kubectl -n $NS delete pvc -l app.kubernetes.io/name=postgresql
        echo -e "${BLUE}Starting db instance${NC}"
        kubectl -n $NS scale statefulset -l app.kubernetes.io/name=postgresql --replicas 1
        echo -e "${BLUE}Awaiting for 'ready' condition${NC}"
        kubectl -n $NS wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql
        sleep 10
        echo -e "${BLUE}Restoring DB${NC}"
        zless $FILE | kubectl -n $NS exec -it db-postgresql-0 -c db-postgresql -- sh -c "PGPASSWORD=$DBPASS psql -U postgres $DB"
    }



    case $ext in
        gz) compressed 
        ;;
        sql) exit 0
        ;;
        *) echo -e "${RED}Unsuported file format${NC}" && dbRestoreHelp
        ;;
    esac
}
