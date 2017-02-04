#printf "Removing old cache data..."
#rm rpki-validator-app-*/data_backup/* -rf
#mv rpki-validator-app-*/data/ rpki-validator-app*/data_backup/
#printf " done!\n"

#printf "Starting Cache and waiting for it to sync...\n"
#./rpki-validator-app-*/rpki-validator.sh start
#while [ ! -f rpki-validator-app-*/data/data.json ]
#do
    ## wait for sync...
    #sleep 1
#done
#printf " done!\n"

rib_csv="$1.formatted"

if [ ! -f "$rib_csv" ]; then
	#convert the rib dump to readable bgp data
	printf "Converting RIB dump to readable BGP...\n"
	./bgpdump -M -O $1.temp $1
	printf " done!\n"

	## take only ASN and Prefix and write them to different files
	printf "Filter unnecessary data, sort and uniq it..."
	awk -F '|' '{print $6 " " $7}' $1.temp | awk '{ print $1 " " $NF }' | sort -u > $1.formatted
	printf " done!\n"
fi

# the old state of the RTRlib
for i in libs/*; do
	name=$(echo $i| cut -d "/" -f 2)
	export LD_PRELOAD=$i/librtr.so
	./rtr-validator $1.formatted $name-result.txt $2 $3
done
# cleanup
printf "Cleanup..."
#rm $1.temp $1.formatted
printf " done!\n"
