printf "Validate prefix data with RIPE API (this takes about a day)...\n"
maxlines=$( wc -l $1 | awk '{ print $1 }' )
counter=1
while read -r prefix asn
do
    result=$( curl -s "localhost:8080/api/v1/validity/AS$asn/$prefix" | jq '.validated_route.validity.state' )
    echo "$prefix $asn $result" >> $1.apiresult
    echo -ne "${counter}/${maxlines} lines processed.\r"
    counter=$((counter+1))
done < $1
printf " done!\n"

# filter and sort the RPKI validation result
sed '/{/d' $1.apiresult | sort -u > rpki-result.txt
