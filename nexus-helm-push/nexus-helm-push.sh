#!/bin/bash
USERNAME=$HELM_NEXUS_USER
PASSWORD=$HELM_NEXUS_PASS
HELMREPO=$HELM_NEXUS_REPO
URL="https://$HELM_NEXUS_URL/service/rest/v1/components?repository=$HELMREPO"

if [[ -f /usr/local/bin/colors ]]; then
  . /usr/local/bin/colors null
else
  cd /tmp
  git clone git@github.com:fruitgum/bash.git
  cd bash/colors
  sudo chmod +x colors
  sudo cp colors /usr/local/bin/colors
  cd ../../
  rm -rf bash
  . /usr/local/bin/colors null
fi



checkErrors(){
	errSum=0
	if [[ -z $USERNAME ]]; then
		errMsg="Please provide username"
		((errSum++))
	elif [[	-z $PASSWORD ]]; then
		errMsg="Please provide password"
		((errSum++))
		
	elif [[ -z $HELMREPO ]]; then
		errMsg="Please provide helm repo name"
		((errSum++))
	elif [[ -z $HELM_NEXUS_URL ]]; then
		errMsg="Prease provide nexus url"
		((errSum++)) 
	fi
	if [[ $errSum -ne 0 ]]; then
		echo -e "${RED}$errMsg${NC}"
		exit 1
	fi
}

nhpHelp(){
	echo -e "\nnexus-helm-push. Allows to upload helm packages to nexus repo"
	echo ""
	echo "Usage: nexus-helm [options] [filename]"
	echo "Options:"
	echo "  -h|--help - This help"
	echo -e "${YELLOW}"
	echo "Example: nexus-helm-push my-chart.tgz"
	echo -e "${NC}\n"
	echo "For correct work you should define next variables:"
	echo "HELM_NEXUS_USER - Nexus user"
	echo "HELM_NEXUS_PASS - Nexus user's password"
	echo "HELM_NEXUS_URL  - Nexus url, eg. nexus.myhost.com"
	echo "HELM_NEXUS_REPO - Nexus helm repo name"
	exit 0
}


checkFile(){
	#this one checks if archive name was defined
	if { [[ -z $FILE ]] || [[ ! -f $FILE ]]; }; then
		echo -e "${GRAY}Archive name: ${NC}\c"
		read -r FILE
	fi
	#this one looking for file
	if [[ ! -f $FILE ]]; then
		echo "${RED}File $FILE not found${NC}"
		exit 1
	fi
}

upload(){
	echo -e "\n${YELLOW}Uploading $FILE to $HELM_NEXUS_URL...${NC}"
	curl -F file=@$FILE -u "$user:$pass" $URL
	if [[ $? -ne 0 ]]; then
		echo -e "${RED}Something went wrong${NC}"
		exit 1
	else
		echo -e "${GREEN}$FILE successfully uploaded!${NC}"
		exit 0
	fi
}


run(){
	checkErrors
	checkFile
	upload
}


case $1 in
	--help|-h) nhpHelp
	;;
	*) FILE=$1; run
	;;
esac
