path=$(pwd)
read -p "Enter the plugin name:" pluginname
rm "$pluginname"-Raise-trap.txt "$pluginname"-Clear-trap.txt "$pluginname"-Switch-handled.txt
touch "$pluginname"-Raise-trap.txt "$pluginname"-Clear-trap.txt "$pluginname"-Switch-handled.txt
rm list-trap.txt
touch list-trap.txt
cd ~/workspace/vsure/centina/sa/profiles
echo -e "Listing Traps........................\n"
for j in `cat $pluginname.xml | grep 'snmp/trap/' | grep -v ".dtd\|snmp/trap/catch-all-trap.xml" | awk -F "\"" '{print$2}' | xargs -n1 -I {} grep "<trap-group id\|<trap id=\|<example id=" {} | sed -e 's/<trap-group id/trapgroupid/' -e 's/<trap id/trapid/' -e 's/<example id/exampleid/' | sed '/w\/o (O)/d' | sed 's/>//'`
do
	list=$(echo $j | awk -F "=" '{print$1}')
	if [ $list = "trapgroupid" ]
	then
	gid=$(echo $j | awk -F "\"" '{print$2}')
	echo -e "Adding traps of $gid\n"
	elif [ $list = "trapid" ]
	then
	tid=$(echo $j | awk -F "\"" '{print$2}')
	elif [ $list = "exampleid" ]
	then
	eid=$(echo $j | awk -F "\"" '{print$2}')
	echo "$gid:$tid:$eid" >>~/myworkspace/trap-script/list-trap.txt
	fi
done
echo -e "Listing Traps for $pluginname done.\nSeparating raise and clear traps..........................................\n"
for i in `cat "$pluginname".xml | grep '<file path="snmp/trap/' | awk -F "\"" '{print$2}' | xargs cat | grep 'trap id\|<switch id="action">\|<property[ ]*name="action"' | sed 's/<//g' | sed -e 's/trap[ ]*id/trap/g' -e 's/switch[ ]*id/switch/g' -e 's/property[ ]*name="action"[ ]*value/value/g' -e 's/>//g' -e 's/\///g'|xargs -n1`
do
switch=$(echo $i| awk -F "=" '{print$1}')
if [ "$switch" = "trap" ]
then
trap=$(echo $i | awk -F "=" '{print$2}')
echo $trap
elif [ "$switch" = "value" ]
then
value=$(echo $i | awk -F "=" '{print$2}')
	if [ "$value" = "RAISE" ]
	then
	echo "$trap" >>~/myworkspace/trap-script/"$pluginname"-Raise-trap.txt
	else
	echo "$trap" >>~/myworkspace/trap-script/"$pluginname"-Clear-trap.txt
	fi
elif [  $switch = "switch" ]
then
echo "$trap" >>~/myworkspace/trap-script/"$pluginname"-Switch-handled.txt
fi
done
read -p "Enter simId: " simid
read -p "Enter Interface ex:(enp0s25:0): " interface
echo -e "\nRaise Traps\n"
cat ~/myworkspace/trap-script/"$pluginname"-Raise-trap.txt | xargs -n1 -I {} grep :{}: ~/myworkspace/trap-script/list-trap.txt  | sed "s/^/send-trap $simid $interface /g"| sed -e '/clear/d' -e '/Clear/d' -e '/CLEAR/d' |sort -u| tee ~/myworkspace/trap-script/"$pluginname"-raise.txt | cat -n
echo -e "\nClear Traps\n"
cat ~/myworkspace/trap-script/"$pluginname"-Clear-trap.txt | xargs -n1 -I {} grep :{}: ~/myworkspace/trap-script/list-trap.txt  | sed -e "s/^/send-trap $simid $interface /g" |sort -u | tee ~/myworkspace/trap-script/"$pluginname"-clear.txt | cat -n
echo -e "\nSwitch Handled\n"
cat ~/myworkspace/trap-script/"$pluginname"-Switch-handled.txt | xargs -n1 -I {} grep :{}: ~/myworkspace/trap-script/list-trap.txt  | sed "s/^/send-trap $simid $interface /g" |sed -e '/clear/d' -e '/Clear/d' -e '/CLEAR/d' |sort -u| tee ~/myworkspace/trap-script/"$pluginname"-switch.txt | cat -n
cd "$path"
rm ~/myworkspace/trap-script/"$pluginname"-Raise-trap.txt ~/myworkspace/trap-script/"$pluginname"-Clear-trap.txt ~/myworkspace/trap-script/"$pluginname"-Switch-handled.txt
