#!/bin/bash
#exit 0
# expose(){
#     NS=$2
#     kind=$3
#     sport=$4

#     exposeHelp(){
#         echo "Usage: easykube expose [namespace] [kind] port(optional)"
#         echo "Example: easykube expose demo svc 8080"
#         echo "Kinds:"
#         echo "  service, svc, s"
#         echo "  deployment, d"
#         echo "  pod"
#         exit 1
#     }

#     case $kind in
#         service|svc|c) resource="service"
#         ;;
#         deployment|d) resource="deployment"
#         ;;
#         pod) resource="pod"
#         ;;
#         *) exposeHelp
#         ;;
#     esac

#     IFS=" " read -a items <<< $(echo $(kubectl -n $NS get $resource"s" | grep -v "NAME" | awk '{print $1"@"$5}'))

#     if [[ -z $items ]]; then
#         echo -e "\nNo $resource"s" available" && exit 1
#     fi

#     for (( i=0; i<${#items[@]}; i++ )); do
#         item=$(echo ${items[i]} | cut -d"@" -f1)
#         port=$(echo ${items[i]} | cut -d"@" -f2 | cut -d"/" -f1)
#         echo -e "   ${GREEN} [$i]: $item${NC}" | table3
#         array+=($item)
#     done

#     echo -e "\nSelect number: \c"
#     read -r c
#     item=${array[c]}
#     echo ""

#     if [[ -z $sport ]]; then
#         sport=$port
#     fi

#     handleConnection(){
#         dir="/tmp/"
#         file="hc-$(uuidgen).sh"
#         echo "
#         CONNFILE=$(echo $CONNFILE)
#         kubectl -n $NS port-forward svc/$svc $sport/$port
#         sleep 3600
#         cat $CONNFILE | jq 'del(.connections | .[] | select(.name=='\"test1\"'))' > /tmp/easykube && cat /tmp/easykube > $CONNFILE
#         exit 0" > $dir$file
#         chmod +x $dir$file
#         # cd $dir && ./$file > /dev/null 2>&1
#         # pid=$!
#         # if [[ $? -ne 0 ]]; then
#         #     echo "Can't establish connection" && exit 1
#         # fi

#         check=cat $CONNFILE | jq '.connections | .[] | select(.name=='\"$NS\"')'
#         if [[ ! -z $check ]]; then
#             port=cat $CONNFILE | jq '.connections | .[] | select(.name=='\"$NS\"') | .port'
#             pid=cat $CONNFILE | jq '.connections | .[] | select(.name=='\"$NS\"') | .pid'
#             echo "$NS already exposed with port $port ($pid)" && exit 1
#         fi
#         echo "jq"
#         cat $CONNFILE | jq '.[] + [{"name":'\"$NS\"', "port":'\"$sport\"', "pid":'\"$pid\"'}]' #> /tmp/easykube.conf && cat /tmp/easykube.conf > $CONFIGFILE
#         echo "$resource $item available at http://127.0.0.1:$sport for a 1 hour"

#     }

#     echo ""
#     echo -e "${YELLOW}$item selected${NC}"
#     echo ""
#     #kubectl -n $NS port-forward svc/$svc $sport/$port & 2>&1 /dev/null
#     handleConnection $item $sport $port
#     exit 0
# }
