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
printf "Converting RIB dump to readable BGP...\n"
./bgpdump -M -O $1.temp $1
printf " done!\n"

#take only ASN and Prefix and write them to different files
printf "Filter unnecessary data, sort and uniq it..."
awk -F '|' '{print $6 " " $7}' $1.temp | awk '{ print $1 " " $NF }' | sed '/{/d' | sort -u > $1.formatted
printf " done!\n"

# the lpfst implementation of the RTRlib
LD_PRELOAD=/home/colin/projects/shell/ripe-rtr-validator/v2/libs/librtr-lpfst/librtr.so ./rtr-validator $1.formatted lpfst-result.txt $2 $3

# the trie implementation of the RTRlib
LD_PRELOAD=/home/colin/projects/shell/ripe-rtr-validator/v2/libs/librtr-trie/librtr.so ./rtr-validator $1.formatted trie-result.txt $2 $3

# the RIPE RPKI validator implementation
sh validate-ripe.sh $1.formatted

# cleanup
printf "Cleanup..."
rm $1.temp $1.formatted*
printf " done!\n"
