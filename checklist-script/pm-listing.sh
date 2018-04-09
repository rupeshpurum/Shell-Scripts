read -p "Enter the Plugin name: " pluginName

#Change the Repo path here
repo="workspace/vsure/centina/sa"

rm "$pluginName"-PM-checklist.csv
for i in `cat "$HOME/$repo/profiles/$pluginName.xml" | grep pm | grep -v templates | awk -F '"' '{print$2}' |grep -v "\.dtd\|if-mib"| xargs -n1 -I {} cat ~/workspace/vsure/centina/sa/profiles/{} | sed -e 's/metricGroup name/\nmetricGroup name/g' -e 's/parameter name/parametername/g' -e 's/oid=/\noid=/g' | grep "metricGroup name\|name\|parametername\|oid\|pmProfile name" | sed -e 's/^[ ]*//g' -e 's/[ ]*$//g' | sed 's/ /#/g' | sed 's/<//g'`
do
	a=$(echo $i | awk -F '=' '{print$1}')
		if [ $a = "metricGroup#name" ]
		then
			metricGroupid=$(echo $i | awk -F '"' '{print$2}')
		elif [ $a = "name" ]
		then
			metricName=$(echo $i | awk -F '"' '{print$2}')
		elif [ $a = "pmProfile#name" ]
		then
			pmProfieName=$(echo $i | awk -F '"' '{print$2}')
		elif [ $a = "parametername" ]
		then
			parameterName=$(echo $i | awk -F '"' '{print$2}')
		elif [ $a = "oid" ]
		then
			oid=$(echo $i | awk -F '"' '{print$2}')
			echo -e  ",$parameterName,$pmProfieName,,,$metricGroupid,$metricName,$oid," | sed 's/#/ /g' >>"$pluginName"-PM-checklist.csv
		
		else
			echo "Abnormal"
		fi	
	
done
path=$(pwd)

echo -e "file path is : $path/$pluginName-PM-checklist.csv"
xdg-open $path/"$pluginName"-PM-checklist.csv