#Author SHANMUKH
#Script to Generate Responses required to test plugin
#This generates some text files during the execution which are auto deleted
#To Debug the script uncomment the lines 6-8 then the debug output will be stored into debug_output.txt
#!/bin/sh
#set -x
#exec 5> debug_output.txt
#BASH_XTRACEFD="5"
touch temp.txt
#Set Path Here
repo="workspace/vsure/centina/sa/profiles"
mibs=$(echo $repo | awk -F "/centina/sa/" '{print$1}')
read -p "Enter plugin profile xml name:" pluginname
mibdumpfolder="$pluginname"
if [ -d "$HOME/$mibs/mibs/$pluginname" ]
then
    echo -e "\n\n\e[36mDirectory $HOME/$mibs/mibs/$pluginname exists \nContinuing Search for indexes in $pluginname folder\e[0m\n"
	tag=0
else
    echo -e "\n\n\e[36mError: Directory $HOME/$mibs/mibs/$pluginname does not exist.\e[0m\n\e[36mSearching for Indexes in all the mibs present in $HOME/$mibs/mibs/ \n\n\n\nSearching in all Mibs takes time...............................\e[0m"
    tag=1
fi
cat "$HOME"/"$repo"/"$pluginname".xml | grep trap | grep -v 'snmp/trap/generic-traps\|snmp/trap/snmpTrap.dtd\|snmp/trap/catch-all-trap' | awk -F "\"" '{print$2}' | xargs -n1 -I {} grep -h '<varbind oid="' "$HOME"/"$repo"/{} | awk -F "\"" '{print$2}' > "$pluginname"-varbind.txt


index1=.1

#This command Gets all the OID's which are present in PM xml's and stores them in file1.txt which is used in Tag-1
grep -o '<file path="pm/.*' "$HOME"/"$repo"/"$pluginname".xml | grep -v '<file path="pm/templates' | awk -F "\"" '{print$2}' | xargs -n1 -I {}  grep -o 'oid="[0-9.]*"' "$HOME"/"$repo"/{} | awk -F "\"" '{print$2}' | sed 's/\s*//g'>file1.txt
#Tag-1
for value in `grep -o 'inventory/.*' ""$HOME"/"$repo"/$pluginname.xml" | awk -F "/" '{print$2}' | awk -F "\"" '{print$1}' | grep -v 'if-mib.xml\|entity'|xargs -n1 -I {} cat "$HOME"/"$repo"/snmp/inventory/{} | sed -e 's/oid="/\noid="/g' -e 's/^.*appends="node.*$//g' -e 's/suffix/\nsuffix/g' | grep -o 'oid="[0-9.]*"\|suffix="[0-9]*"\|<table name=".* \| <table appends=".*\|<column name=.*' | sed -e 's/<table appends/name/g' -e 's/<table name/name/g' -e 's/<column name/column/g' | sed 's/\s*//g'`
do
a=$(echo $value| awk -F "=" '{print$1}')
	if [ $a = oid ]
	then
		oid=$(echo $value | awk -F "\"" '{print$2}')
			hand=1
			for t in `egrep "$oid" "$HOME"/myworkspace/mib-dump-script/"$pluginname"-varbind.txt | sort -u`
			do
			var=$(echo $t | awk -F "$oid" '{print$2}')
			variable=$(echo $var | sed 's/^.[0-9]*//')
				if [ -z "$variable" ]
				then
					echo ""
				else
					array[$hand]=${variable}
					let hand++
				fi
			done
			take=${hand}
			#Loop to convert count to formatted index
			for ((i=1; i<"index" ; i++))
			do
				index1="$index1.1"
			done

			#loop to get pm with index
			for pm in `grep ".${oid}" file1.txt | sort -u`
			do
				#echo "$pm$index1 = INTEGER: 1" >>temp.txt
				echo "$pm$index1 = INTEGER: 1" >>temp.txt
					for((addingtrapresponse=1;addingtrapresponse<"$take";addingtrapresponse++))
						{
							if [ -z "$addingtrapresponse" ]
							then
							echo ""
							else
								echo  "$pm${array[$addingtrapresponse]} = STRING: $columnname" >>temp.txt
							fi
						}
				
				
				
			done
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
	elif [ $a = column ]
	then
	columnname=$(echo $value | awk -F "\"" '{print$2}')

	elif [ $a = suffix ]
	then
		suffix=$(echo $value | awk -F "\"" '{print$2}')
		index1=.1
			#Loop to convert count to formatted index
			for ((i=1; i<"index" ; i++))
			do
				index1="$index1.1"
			done

			syntax=$( grep 'mib-repository.xml' ""$HOME"/"$repo"/$pluginname.xml"| awk -F "\"" '{print$2}' | xargs -n1 -I {} cat "$HOME"/"$repo"/{} | grep "$columnname"|head -1 | grep -o "type=.*" | awk -F "\"" '{print$2}')
		#line to print the inventory oid's
		if [ "$syntax" = string ]
		then
			if [ -z "$index1" ]
			then
			echo ""
			else
				echo  ".${oid}.${suffix}${index1} = STRING: $columnname" >>temp.txt
			fi
		for((addingtrapresponse=1;addingtrapresponse<"$take";addingtrapresponse++))
		{
			if [ -z "$addingtrapresponse" ]
			then
			echo ""
			else
				echo  ".${oid}.${suffix}${array[$addingtrapresponse]} = STRING: $columnname" >>temp.txt
			fi
		}
		else
			if [ -z "$index1" ]
			then
			echo ""
			else
				echo  ".${oid}.${suffix}${index1} = INTEGER: 1" >>temp.txt
			fi
		for((addingtrapresponse=1;addingtrapresponse<"$take";addingtrapresponse++))
		{
			if [ -z "$addingtrapresponse" ]
			then
			echo ""
			else
				echo  ".${oid}.${suffix}${array[$addingtrapresponse]} = INTEGER: 1" >>temp.txt
			fi
		}
		fi
		index1=.1
	elif [ $a = name ]
	then
		table=$(echo $value | awk -F "\"" '{print$2}')
		path=$(pwd)
		if [ $tag = 0 ]
		then
		cd "$HOME"/"$mibs"/mibs/"$mibdumpfolder"/  #to search in exact plugin mibs
		else
		cd "$HOME"/"$mibs"/mibs/
		fi

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
				echo -e "\n\e[1;31mUnable to compute the index for \e[0m\e[31m$table\e[0m\e[1;31m using index '1'\ncheck & Change manually for \"$oid\"\e[0m"
			fi
		egrep -whr -A1000 "\b$table\b.*OBJECT-TYPE" | head -1000 | sed 's/AUGMENTS/INDEX/g'|awk '/INDEX/, /::=/' | sed "s/$table/shan/"| awk '1;/shan/{exit}' | sed "s/shan/$table/"
		echo -e "table= \e[32m$table\e[0m \t\tIndex=\e[1;32m$index\e[0m\n"
		cd "$path"

   	fi
done
#Loop which adds responses of Node metrics
for node in `cat "$HOME"/"$repo"/"$pluginname".xml | grep '<file path="pm/'| awk -F "\"" '{print$2}' | grep -v 'pm/templates/\|.dtd\|if' | xargs -n1 -I {} cat "$HOME"/"$repo"/{} | grep 'indexed="false"' | grep -o 'oid="[0-9.]*"' | awk -F "\"" '{print$2}'`
do
	#a=$(echo $node | awk -F "." '{print$NF}')
		#if [ "$a" = 0 ]
		#then
			#echo $node = INTEGER: 1>>temp.txt
		#else
			#echo $node.0 = INTEGER: 1>>temp.txt
		#fi
		#a=$(shuf -i 1-10 -n 10)
		#b=$(echo $a | sed 's/ /,/g')
		echo $node = INTEGER: 1 >>temp.txt
done
cp if-response.txt mibdump.txt
sed 's/^$//g' -i temp.txt
#echo -e "\nThe responses required for plugin are below:"
#cat temp.txt | sort -u | sort -V
sort -u temp.txt |sort -V >>mibdump.txt
sort -V mibdump.txt >"$temppm".txt

for i in `cat $HOME/myworkspace/mib-dump-script/"$temppm".txt | sed 's/ //g'`; do a=$(shuf -i 1-10 -n 10); b=$(echo $a | sed 's/ /,/g'); echo $i | sed "s/INTEGER: 1/VALUES:\"INTEGER:$b\"/g"; done >"$pluginname".txt
echo -e "\n\n\n\n\n\nResponse is in file: $path/$pluginname.txt\n\n\n\n"
sed -i 's/=/ = /g' $pluginname.txt
sed -i 's/:/: /g' $pluginname.txt
echo "plugin name is $pluginname"
sed "s/tag\-pluginname/$pluginname/" $pluginname.txt -i
sed "s/tag\-nodename/$pluginname-gen/" $pluginname.txt -i
rm -f temp.txt file1.txt "$pluginname"-varbind.txt "$temppm".txt
path=$(pwd)
#echo -e "\n\n\n\n\n\nOutput is in file: $path/$pluginname.txt\n\n\n\n"
xdg-open "$path/$pluginname.txt"

