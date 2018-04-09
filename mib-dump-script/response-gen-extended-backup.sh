#Author SHANMUKH
#!/bin/sh
#Script to Generate Responses
#This generates some text files during the execution which are deleted by script itself after execution completion
#The Debug output is Present in debug_output.txt
#set -x
#exec 5> debug_output.txt
#BASH_XTRACEFD="5"
touch temp.txt temp-syntax.txt
read -p "Enter plugin profile xml name:" pluginname
mibdumpfolder="$pluginname"
index1=.1

#This command Gets all the OID's which are present in PM xml's and stores them in file1.txt which is used in later part
grep -o '<file path="pm/.*' ~/workspace/vsure/centina/sa/profiles/"$pluginname".xml | grep -v '<file path="pm/templates' | awk -F "\"" '{print$2}' | xargs -n1 -I {}  grep -o 'oid="[0-9.]*"' ~/workspace/vsure/centina/sa/profiles/{} | awk -F "\"" '{print$2}' | sed 's/\s*//g'>file1.txt

for value in `cat ~/workspace/vsure/centina/sa/profiles/"$pluginname".xml | grep -o 'inventory/.*' | awk -F "/" '{print$2}' | awk -F "\"" '{print$1}' | grep -v 'if-mib.xml\|entity'|xargs -n1 -I {} cat ~/workspace/vsure/centina/sa/profiles/snmp/inventory/{} | sed -e 's/oid="/\noid="/g' -e 's/^.*appends="node.*$//g' -e 's/suffix/\nsuffix/g' | grep -o 'oid="[0-9.]*"\|suffix="[0-9]*"\|<table name=".* \| <table appends=".*\|<column name=.*' | sed -e 's/<table appends/name/g' -e 's/<table name/name/g' -e 's/<column name/column/g' | sed 's/\s*//g'`
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
				#echo $pm
				echo "$pm$index1 = INTEGER: 1" >>temp.txt
			done
		#index1=.1
	elif [ $a = column ]
	then
	columnname=$(echo $value | awk -F "\"" '{print$2}')

	elif [ $a = suffix ]
	then
		suffix=$(echo $value | awk -F "\"" '{print$2}')
		index1=.1
			#loop to get pm with index
			#for pm in `grep ".${oid}" file1.txt`
			#do
				#echo $pm
				#echo "$pm$index1 = INTEGER: 1" >>temp.txt
			#done
			#Loop to convert count to formatted index
			for ((i=1; i<"index" ; i++))
			do
				index1="$index1.1"
			done

			syntax=$(cat ~/workspace/vsure/centina/sa/profiles/"$pluginname".xml | grep 'mib-repository.xml' | awk -F "\"" '{print$2}' | xargs -n1 -I {} cat ~/workspace/vsure/centina/sa/profiles/{} | grep "$columnname"|head -1 | grep -o "type=.*" | awk -F "\"" '{print$2}')
		#line to print the inventory oid's
		if [ "$syntax" = string ]
		then
		#echo  ".${oid}.${suffix}${index1} = STRING: $columnname" >>temp-syntax.txt
		#echo "$columnname with suffix $suffix is string"
		echo  ".${oid}.${suffix}${index1} = STRING: $columnname" >>temp.txt
		else
		echo  ".${oid}.${suffix}${index1} = INTEGER: 1" >>temp.txt
		fi
		#Loop to convert count to formatted index
		index1=.1


	elif [ $a = name ]
	then
		table=$(echo $value | awk -F "\"" '{print$2}')
		path=$(pwd)
		#echo "$table"
		cd ~/workspace/vsure/mibs/"$mibdumpfolder"/

			#Finds the Index
			if [  "$table" = "ifTable" ]
			then
			index=1
			else
				if check=$(egrep -whr -A1000 "\b$table\b.*OBJECT-TYPE" | head -1000 |awk '/INDEX/, /::=/' | sed 's/AUGMENTS/INDEX/g'| sed "s/$table/shan/"| awk '1;/shan/{exit}' | grep -q shan)
				then
				index=$(egrep -whr -A1000 "\b$table\b.*OBJECT-TYPE" | head -1000 | sed 's/AUGMENTS/INDEX/g'|awk '/INDEX/, /::=/' | sed "s/$table/shan/"| awk '1;/shan/{exit}' |sed 's/,[ ]*[a-z]/\n/g'| sed 's/\s*//g' | sed '/^\s*$/d' |  awk '/{/,/}/' | sed -e 's/{/{\n/g' -e 's/}/\n}/g'| sed '/^\s*$/d' | sed '/^\s*$/d'| sed -e '/{/d' -e '/}/d' -e '/INDEX/d' | grep -vic "shan1" ) #|sed 's/,/\n/g'| sed 's/^$//'  |  grep -vic "${table}" | sed -e '/"$table"/d' -e '/INDEX/d' | grep -c "\b[a-zA-Z]*\b"
				else
				index=0
				fi
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
			echo $node >>temp.txt
		fi
done
cp if-response.txt mibdump.txt
sed 's/^$//g' -i temp.txt
echo -e "\n\n\n\n\n\nOutput is in file: $path/mibdump.txt\n\n\n\n"
echo -e "\nThe responses required for plugin are below:"
cat temp.txt
sort -u temp.txt |sort -V >>mibdump.txt
#| sed 's/$/ = INTEGER: 1/'>>mibdump.txt
rm -f temp.txt file1.txt
path=$(pwd)
echo -e "\n\n\n\n\n\nOutput is in file: $path/mibdump.txt\n\n\n\n"

#xdg-open "$path/mibdump.txt"

