date
pluginFileName=$1

REPO_LOCATION=$PWD

if [ -z "$pluginFileName" ]; then
	echo -e "Empty Argument run below commands for help \n    ./trap-checklist -h  \n    ./trap-checklist --h"
	exit
fi;

if [ "$1" == "--h" ]; then
  echo "Usage: 
  
  Please run the script from centina folder in the repo.
  
  classificationFromTextFile.sh [text_file] > [csv_file]
  
  text_file : It is a text file containing all the plugin names whose classification tag needs to be added
  
  Format of text file:
  plug-in_name1
  plug-in_name2
  and so on...
  
  csv_file : Where the description, trapid, etc are extracted and copied in csv format"
  exit 0
fi;

if [ "$1" == "-h" ]; then
  echo "Usage: "
  echo " Please run the script from centina folder in the repo.
  calssifiation.sh [text_file] > [csv_file]
  text_file : It is a text file containing all the plugin names whose classification tag needs to be added line by line
  csv_file : Where the description, trapid, etc are extracted and copied in csv format"
  exit 0
fi;

if [ -z $(ls ~| grep ExmlFiles) ]; then
	cd ~
	mkdir "ExmlFiles"
	cd -
else
	cd ~
	rm -r ExmlFiles
	mkdir "ExmlFiles"
	cd -
fi;

cat $pluginFileName | while read -r pluginFile
do
	echo $REPO_LOCATION
	cat "$REPO_LOCATION/sa/profiles/"$pluginFile | while read -r line
	do
		if [ ! -z $(echo $line | awk '/<file path="snmp\/trap\//{print $0}' | awk -F'/' '{print $2}' ) ]; then
			
			path=$(echo $line | awk -F "\"" '{print$2}' | grep trap | grep -v "dtd\|snmp/trap/generic-traps-mib.xml\|snmp/trap/catch-all-trap.xml")
			cd ~
			cp "${REPO_LOCATION}/sa/profiles/$path" "ExmlFiles/"
		fi;
	done
done

cd $HOME/ExmlFiles/
ls -1 | xargs -n1 -I {} sed -i '/<example/,/<\/example>/d' {} 
ls -1 | xargs -n1 -I {} sed -i '/<switch id/,/<\/switch>/d' {} 
cd -

echo "TrapId, TrapOidValue, EnterpriseValue, SpecificTrapValue,Trap XML name, Action ,Alarm Severity, Alarm classification, Description"

#Iterates through the directory for each xml file
for file in ~/ExmlFiles/*.xml
do
	#Lists every line in the file and iterate through the file
	cat $file | while read -r line

	do
		#Get the name of the file
		MibName=$(cat $file | grep 'trap-group id=' | awk -F'"' '{print $2}')	
			#Get the specific-trap value
			tempSpecific=$(echo $line | grep "specific-trap value" | awk -F '"' '{print$2}')
			if [ ! -z $tempSpecific ]
			then
			SpecificTrapValue=$tempSpecific
			fi
			tempEnterprise=$(echo $line | grep "enterprise value" | awk -F '"' '{print$2}')
			#Get the enterprise value 
			if [ ! -z $tempEnterprise ]
			then
			a=$tempEnterprise
			EnterpriseValue=$(echo $a | sed 's/[\\\(\)\?]//g')
			#| sed 's/[\(\)\?]//g' | sed 's/\\//g' 
			fi
			tempOid=$(echo $line | grep "trap-oid value" | awk -F '"' '{print$2}')
			#Get the trap-oid value 
			if [ ! -z $tempOid ]
			then
			b=$tempOid
			TrapOidValue=$(echo $b | sed 's/[\\\(\)\?]//g')
			#| sed 's/\\//g' 
			fi
		
			# Stop reading the description once trap condition tag is identified
			if [ ! -z $(echo $line | awk '/<trap-condition>/{print $0}' | awk -F'<' '{print $2}') ]; then
				descEnd=$(echo $line | awk '/<trap-condition>/{print $0}' | awk -F'<' '{print $2}')
				descStart="false"
			fi;
		
			# Read the multi-line description as a single line
			if [ "$descStart" = "true" ] && [  -z $descEnd ]; then
				line1=$(echo $line | tr -d '\n' | tr -d '\r')
				line1=${line1/'<!--'/' '}
				line1=${line1/'-->'/' '}
				checkExplicit="true"
				description="$description $line1"
			fi;
			
			# Get the trap id and start reading the description
			if [ ! -z $(echo $line |awk '/trap id/{print $0}' | awk -F'"' '{print $2}') ]; then
				nam=$(echo $line |awk '/trap id/{print $0}' | awk -F'"' '{print $2}')
				descStart="true"
				descEnd=''
			fi;
			tempSeverity=$(echo $line | awk '/<property name="perceivedSeverity"/{print $0}' | awk -F'"' '{print $4}')
			#Get the severity of trap
			if [ ! -z $tempSeverity ] ; then
				severity=$tempSeverity
				
			fi;
			tempAction=$(echo $line | awk '/<property name="action"/{print $0}' | awk -F'"' '{print $4}')
			#Get the Action of trap
			if [ ! -z $tempAction ] ; then
				action=$tempAction
				
			fi;
			tempClass=$(echo $line | awk '/<property name="classification"/{print $0}' | awk -F'"' '{print $4}')
			#Get the classification of the trap
			if [ ! -z $tempClass ] ; then
				classification=$tempClass
				
			fi;
			
			#Check explicit tag if it is inside alarm object block
			if [ "$checkExplicit" = "true" ]; then
				explicit=$(echo $line | awk '/<\/explicit>/{print $0}' | awk -F'/' '{print $2}')
			fi;
			
			#Once explicit block is completed set the default severity if it is empty
			if [ ! -z $explicit ] && [ "$severity" != "INFO" ] && [ "$severity" != "WARNING" ] && [ "$severity" != "MINOR" ] && [ "$severity" != "MAJOR" ] && [ "$severity" != "CRITICAL" ] &&  [ "$severity" != "INDETERMINATE" ]; then
				severity="SET_BY_TRAP_RESPONSE"
			fi;
			
			#Once explicit block is completed set the default classification as unknown if it is empty
			if [ ! -z $explicit ] && [ "$classification" != "NODE_FAILURE" ] && [ "$classification" != "REACHABILITY_FAILURE" ] && [ "$classification" != "CARD_FAILURE" ] && [ "$classification" != "EQUIPMENT_FAILURE" ] && [ "$classification" != "INTERFACE_FAILURE" ] &&  [ "$classification" != "LAYER_1_FAILURE" ] &&  [ "$classification" != "LAYER_2_FAILURE" ] &&  [ "$classification" != "LAYER_3_FAILURE" ] &&  [ "$classification" != "APPLICATION_FAILURE" ] &&  [ "$classification" != "ABNORMAL_PERFORMANCE" ] &&  [ "$classification" != "OTHER_FAILURE" ] &&  [ "$classification" != "OTHER_SYMPTOM" ] &&  [ "$classification" != "INDETERMINATE" ]; then
				classification="unknown"
			fi;
			
			# once alarm block is completed echo all the data seperated by comma in csv format
			if  [ ! -z "$MibName" ] && [ ! -z "$nam" ]&& [ ! -z "$severity" ] && [ ! -z "$descEnd" ] && [ "$descStart" = "false" ] && [ "$checkExplicit" = "false" ]; then
				description=$( echo "$description" | awk '$1=$1' ORS=' ' | sed -e "s/[,\";]/ /g")
				echo "$nam,$TrapOidValue,$EnterpriseValue,$SpecificTrapValue,$MibName,$action,$severity,$classification,$description"
				unset MibName nam severity flag descEnd description classification explicit action SpecificTrapValue EnterpriseValue TrapOidValue
				descStart="false"
			fi;
			
			# Dont check for explicit if the current line is out of alarm block
			if [ ! -z $(echo $line | awk '/<\/alarm>/{print $0}' ) ]; then
			  checkExplicit="false"
			fi;
			
	done
done

date	
