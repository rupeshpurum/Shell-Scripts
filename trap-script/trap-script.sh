path=$(pwd)
read -p "Enter the plugin name:" pluginname
rm "$pluginname"-Raise-trap.txt "$pluginname"-Clear-trap.txt "$pluginname"-Switch-handled.txt
touch "$pluginname"-Raise-trap.txt "$pluginname"-Clear-trap.txt "$pluginname"-Switch-handled.txt
cd ~/workspace/vsure/centina/sa/profiles


for i in `cat "$pluginname".xml | grep '<file path="snmp/trap/' | awk -F "\"" '{print$2}' | xargs cat | grep 'trap id\|<switch id="action">\|<property[ ]*name="action"' | sed 's/<//g' | sed -e 's/trap[ ]*id/trap/g' -e 's/switch[ ]*id/switch/g' -e 's/property[ ]*name="action"[ ]*value/value/g' -e 's/>//g' -e 's/\///g'|xargs -n1`
do
switch=$(echo $i| awk -F "=" '{print$1}')
#~ echo $i
if [ "$switch" = "trap" ]
then
trap=$(echo $i | awk -F "=" '{print$2}')
echo $trap
elif [ "$switch" = "value" ]
then
value=$(echo $i | awk -F "=" '{print$2}')
#~ echo $value
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

#kdiff3 ~/myworkspace/trap-script/"$pluginname"-Raise-trap.txt ~/myworkspace/trap-script/"$pluginname"-Clear-trap.txt ~/myworkspace/trap-script/"$pluginname"-Switch-handled.txt


echo -e "\n\n\n\n\n\n\n\n\n\n\nCopy Paste all the Listed traps from simulator in list-trap.txt\n\n\n\n"



read -p "Enter: " option
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
