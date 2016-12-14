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

 #convert the rib dump to readable bgp data
#printf "Converting RIB dump to readable BGP...\n"
#./bgpdump -M -O $1.temp $1
#printf " done!\n"

## take only ASN and Prefix and write them to different files
#printf "Filter unnecessary data, sort and uniq it..."
#awk -F '|' '{print $6 " " $7}' $1.temp | awk '{ print $1 " " $NF }' | sort -u > $1.formatted
#printf " done!\n"

# the old state of the RTRlib
LD_PRELOAD=/home/colin/projects/shell/ripe-rtr-validator/v2/libs/librtr-old/librtr.so ./rtr-validator $1.formatted old-result.txt $2 $3

# the trie fix by Andreas
LD_PRELOAD=/home/colin/projects/shell/ripe-rtr-validator/v2/libs/librtr-trie/librtr.so ./rtr-validator $1.formatted trie-result.txt $2 $3

# the fix by Sebastian
LD_PRELOAD=/home/colin/projects/shell/ripe-rtr-validator/v2/libs/librtr-fix/librtr.so ./rtr-validator $1.formatted fix-result.txt $2 $3

# cleanup
printf "Cleanup..."
#rm $1.temp $1.formatted
printf " done!\n"
