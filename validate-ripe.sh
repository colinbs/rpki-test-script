printf "Validate prefix data with RIPE API (this takes about a day)...\n"
while read -r prefix asn
do
    result=$( curl "localhost:8080/api/v1/validity/AS$asn/$prefix" | jq '.validated_route.validity.state' )
    echo "$prefix $asn $result" >> $1.apiresult
done < $1
printf " done!\n"
