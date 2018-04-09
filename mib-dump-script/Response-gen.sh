#Script to Generate Responses 
#This generates some text files during the execution which are deleted by script itself after execution completion
#The Debug output is Present in debug_output.txt

#!/bin/sh
set -x
exec 5> debug_output.txt
BASH_XTRACEFD="5"
touch temp.txt
read -p "Enter plugin profile xml name:" pluginname
mibdumpfolder="$pluginname"


#This command Gets all the OID's which are present in PM xml's and stores them in file1.txt which is used in later part
grep -o '<file path="pm/.*' ~/workspace/vsure/centina/sa/profiles/"$pluginname".xml | grep -v '<file path="pm/templates' | awk -F "\"" '{print$2}' | xargs -n1 -I {}  grep -o 'oid="[0-9.]*"' ~/workspace/vsure/centina/sa/profiles/{} | awk -F "\"" '{print$2}' >file1.txt 



for value in `cat ~/workspace/vsure/centina/sa/profiles/"$pluginname".xml | grep -o 'inventory/.*' | awk -F "/" '{print$2}' | awk -F "\"" '{print$1}' | grep -v 'if-mib.xml\|entity'|xargs -n1 -I {} cat ~/workspace/vsure/centina/sa/profiles/snmp/inventory/{} | sed -e 's/oid="/\noid="/g' -e 's/^.*appends="node.*$//g' | grep -o 'oid="[0-9.]*"\|suffix="[0-9]*"\|<table name=".* \| <table appends=".*' | sed -e 's/<table appends/name/g' -e 's/<table name/name/g'`
do 

a=$(echo $value| awk -F "=" '{print$1}')
	if [ $a = oid ]
	then
 
		oid=$(echo $value | awk -F "\"" '{print$2}')
 
			#Loop to convert count to formatted index
			for ((i=1; i<"index" ; i++))
			do
				index1="$index1.1"
			done
 
 
			#loop to get pm with index
			for pm in `grep ".${oid}" file1.txt`
			do
				echo "$pm$index1" >>temp.txt
			done
		index1=.1
    
	elif [ $a = suffix ]
	then
		suffix=$(echo $value | awk -F "\"" '{print$2}')
		index1=.1

			for ((i=1; i<"index" ; i++))
			do
				index1="$index1.1"
			done
		#line to print the inventory oid's
		echo  ".${oid}.${suffix}${index1}" >>temp.txt
		#Loop to convert count to formatted index
			
		index1=.1
	elif [ $a = name ]         
	then
		table=$(echo $value | awk -F "\"" '{print$2}')
		path=$(pwd)
		cd ~/workspace/vsure/mibs/"$mibdumpfolder"/
     
			#Finds the Index 
			if [  "$table" = "ifTable" ]
			then
			index=1
			else
			
			index=$(egrep -whr -A100 "$table[ ]*OBJECT-TYPE" | head -100 |awk '/INDEX/	, /::=/'|sed 's/,[ ]*[a-z]/\n/g'| sed 's/\s*//g' | sed '/^\s*$/d' |  awk '/{/,/}/' | sed -e 's/{/{\n/g' -e 's/}/\n}/g'| sed '/^\s*$/d' | sed '/^\s*$/d'| sed -e '/{/d' -e '/}/d' -e '/INDEX/d' | grep -vic "${table}" ) #|sed 's/,/\n/g'| sed 's/^$//'  |  grep -vic "${table}" | sed -e '/"$table"/d' -e '/INDEX/d' | grep -c "\b[a-zA-Z]*\b"
			fi
			#Assigns default 1 if the table is not found in mibs
			if [ $index = 0 ]
			then
				index=1
				echo -e "\n Unable to find $table in the mibs of folder $pluginname so assigning its index as 1 in response"
			fi
     
     
		cd "$path"
		echo -e "\ntable= $table\t\tIndex=$index"
     
	fi
done

#Loop which adds responses of Node metrics
for node in `cat ~/workspace/vsure/centina/sa/profiles/"$pluginname".xml | grep '<file path="pm/'| awk -F "\"" '{print$2}' | grep -v 'pm/templates/\|.dtd\|if' | xargs -n1 -I {} cat ~/workspace/vsure/centina/sa/profiles/{} | grep 'indexed="false"' | grep -o 'oid="[0-9.]*"' | awk -F "\"" '{print$2}'`   
do
	a=$(echo $node | awk -F "." '{print$NF}')
		if [ "$a" = 0 ]
		then
			echo $node >>temp.txt
		else
			echo $node.0 >>temp.txt
		fi
done


cp if-response.txt mibdump.txt
sed 's/^$//g' -i temp.txt
sort -u temp.txt |sort -V | sed 's/$/ = INTEGER: 1/'>>mibdump.txt
rm -f temp.txt file1.txt



