
#!/bin/bash
#set -x
#exec 5> debug_output.txt
#BASH_XTRACEFD="5"

index=0
path="/home/sthummala/workspace/vsure/centina/sa/profiles"
read -p "Enter the Plugin name: " pluginname
for clm in `cat "$path/$pluginname".xml | grep 'inventory\|pm' | awk -F "\"" '{print$2}' | grep -v '.dtd\|templates\|if\|entity\|pm' | xargs -n1 -i grep -o oid=".*" $path/{} | awk -F "\"" '{print$2}'`
do
	for repo in `cat $path/"$pluginname".xml | grep "snmp/mib-repository/$pluginname" | grep -v "snmp/mib-repository/all-nodes.xml"| awk -F "\"" '{print$2}' | xargs -I {} cat $path/{} |sed '/<list id /d'| sed 's/<\/entry>/\n<\/entry>/g'`
	do
	diff=$(echo $repo | awk -F "=" '{print$1}')
		if [ $diff = "<entry"  ]
		then
		let index++
		elif [ $diff = "id"  ]
		then

		a[$index]=$(echo $repo | awk -F "\"" '{print$2}')
		elif [ $diff = "</entry>" ]
		then
		let index--
		elif [ $diff = "name"  ]
		then
		compare=$(echo $repo | awk -F "\"" '{print$2}')
				if [ $compare = "$clm" ]
				then
				echo -e "$clm\n\n"
				size=${#a[*]}
				let size=size-2
				for((i=1;i<=size;i++))
				{
				oid="$oid.${a[i]}"
				}
				echo $oid
				break


				fi

		fi
	done
	len=${#a[*]}
	#let size=size-2
	for((i=1;i<=len;i++))
	{
	#oid="$oid.${a[i]}"
	unset a[$i]
	}
#echo $oid

done



