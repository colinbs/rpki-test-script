printf "Prepare temp files for analysis..."
awk '{ print $NF }' $1 >> $1.short
awk '{ print $NF }' $2 >> $2.short
awk '{ print $NF }' $3 >> $3.short

sed 's/\"//g' $1.short > $1.short.tmp
sed 's/\"//g' $2.short > $2.short.tmp
sed 's/\"//g' $3.short > $3.short.tmp

:|paste -d' ' $1.short.tmp - $2.short.tmp - $3.short.tmp > merge.txt

sed 's/\s\+/ /g' merge.txt > merge.txt.tmp
sed 's/\"//g' merge.txt.tmp > merge.txt
printf " done!\n"

maxlines=$( wc -l merge.txt | awk '{ print $1 }' )
counter=1

printf "%-18s %-6s | %-8s | %-8s | %-8s\n" "Prefix/Length" "ASN" "lpfst" "trie" "RPKI" > statistics.txt
echo "----------------------------------------------------------" >> statistics.txt
printf "Analyze data..."
while read -r column1 column2 column3
do
    if [ "$column1" != "$column2" -o "$column1" != "$column3" ]
    then
        line=$( sed -n "$counter p" $1 | awk '{ print $1 " " $2 }' )
        #echo -e "$line\t\t|\t$column1\t|\t$column2\t|\t$column3" >> statistics.txt
        printf "%-18s %-6s | %-8s | %-8s | %-8s\n" $line $column1 $column2 $column3 >> statistics.txt
    fi
    counter=$((counter+1))
    echo -ne "${counter}/${maxlines} lines processed.\r"

done < merge.txt

printf " \ndone!\n"

printf "Cleanup temp data..."
rm *.short* merge*
printf " done!\n"
