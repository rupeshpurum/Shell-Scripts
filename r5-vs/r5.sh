repo=workspace/r6/centina/sa/profiles
vsure=workspace/vsure/centina/sa/profiles
read -p "Enter the plugin name: " pluginname
rm $pluginname-list.csv
rm -rf templates
mkdir templates
touch  $pluginname-list.csv
[ ! -f "$HOME/$vsure/$pluginname".xml ] && cp "$HOME/$repo/$pluginname".xml "$HOME/$vsure/$pluginname".xml || echo "Profile xml is already present in vsure" 
for l in `cat "$HOME/$repo/$pluginname".xml | awk '/<dependencies>/,/<\/dependencies>/' | grep -v "snmp/device/snmpDevice.dtd\|snmp/mib-repository/all-nodes.xml\|.dtd\|inventory\|pm\|trap" | awk -F "\"" '{print$2}'`
do
[ ! -f "$HOME/$vsure/$l" ] && cp "$HOME/$repo/$l" "$HOME/$vsure/$l" || echo -e " \e[36m$l file is already present\e[0m"
done 

for i in `cat "$HOME/$repo/$pluginname".xml | grep "snmp/inventory/" | grep -v ".dtd\|if-mib\|entity-mib" | awk -F "\"" '{print$2}' | xargs -n1 -I {} grep -o 'invProfile name=\".*\|table name=\".*\|group id=\".*' $HOME/$repo/{} | sed 's/ //g'`
do
a=$(echo $i | awk -F "=" '{print$1}')
	if [ $a == invProfilename ]
	then
	mibname=$(echo $i | awk -F "\"" '{print$2}')
	elif [ $a == tablename ]
	then
	tablename=$(echo $i | awk -F "\"" '{print$2}')
	
	elif [ $a == groupid ]
	then
	groupid=$(echo $i | awk -F "\"" '{print$2}')
	echo $mibname,$tablename,$groupid >> $pluginname-list.csv
	fi	
done
for j in `awk -F "," '{print$1}' $pluginname-list.csv | sort -u `
do
	for k in `grep "$j" $pluginname-list.csv | awk -F "," '{print$2}' | sort -u`
	do
		
		#code which creates templates
		cp template.txt templates/"$j.$k".xml
		sed "s/<perf-template name=\"template\">/<perf-template name=\"$j.$k\">/g" templates/"$j.$k".xml -i
				for id in `grep $k $pluginname-list.csv | awk -F "," '{print$3}'`
				do
					echo -en "\t\t<value>$id</value>\n" >>templates/"$j.$k".xml
				done
		
		cat append.xml >>templates/"$j.$k".xml &
		
	done
done


sed "2i \<\!DOCTYPE module PUBLIC \"profile.dtd\" \"profile.dtd\"\>" "$HOME/$vsure/$pluginname".xml -i 
sed "2i <\!DOCTYPE snmp-profile PUBLIC \"snmp/device/snmpDevice.dtd\" \"snmpDevice.dtd\">" "$HOME/$vsure/snmp/device/$pluginname".xml -i 
sed 's/<\/dependencies>/  <file path=\"snmp\/jars\/pluginLib.jar\" version=""\/>\n  <\/dependencies>/' "$HOME/$vsure/$pluginname".xml -i
sed -i "s/<snmp-profile id=\".*\"/<snmp-profile id=\"$pluginname\" profileClass=\"centina.sa.plugins.CiscoPluginImpl\"/g" "$i"

