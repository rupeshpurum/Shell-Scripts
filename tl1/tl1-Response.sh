read -p "Enter the invenotory file name: " file
read -p "Enter the Node name: " node
rm "$file"-endpoints-sim.txt "$file"-endpoints-csv.txt
touch "$file"-endpoints-sim.txt "$file"-endpoints-csv.txt
echo "Response for Sim" > "$file"-endpoints-sim.txt
echo "Response for CSV" > "$file"-endpoints-csv.txt
path="/home/sthummala/workspace/vsure/centina/sa/profiles/tl1/inventory"
for i in `cat "$path"/"$file".xml | grep "<command-set name=\|<command name=\|<example><\!\[CDATA\[\"" | sed 's/ //g'`
do
#echo $i
a=$(echo $i|awk -F "=" '{print$1}')
	if [ $a == "<commandname" ]
	then
	tempcommand=$(echo $i | awk -F "\"" '{print$2}')
    echo -e "\t<command name=\"$tempcommand\">" >>"$file"-endpoints-sim.txt
	temp=$(echo $tempcommand | sed 's/RTRV-//g')
	echo -e "\t" "" "" "<type>$temp</type>\n\t</command>" >>"$file"-endpoints-sim.txt
	elif [ $a == "<command-setname" ]
	then
	break
	else
	pm=$(echo $i | awk -F "\"" '{print$2}'| awk -F ":" '{print$1}' | awk -F "," '{print$1}')
	random=$(shuf -i 1-200 -n 1)
	echo -e "$random,$node,$temp-$pm,$temp" >> "$file"-endpoints-csv.txt
	echo -n "==="

 	fi

done
echo -e ">Complete\n"
echo -e "file for sim file "$file"-endpoints-sim.txt \n\nfile required for CSV is in "$file"-endpoints-csv.txt"
#xdg-open "$file"-endpoints-sim.txt
#xdg-open "$file"-endpoints-csv.txt
echo -e "\n\n\n"
