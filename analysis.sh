printf "Prepare temp files for analysis..."
awk '{ print $NF }' $1 >> $1.short
awk '{ print $NF }' $2 >> $2.short

sed 's/\"//g' $1.short > $1.short.tmp
sed 's/\"//g' $2.short > $2.short.tmp

:|paste -d' ' $1.short.tmp - $2.short.tmp > $1.$2.merge.txt

sed 's/\s\+/ /g' $1.$2.merge.txt > $1.$2.merge.txt.tmp
sed 's/\"//g' $1.$2.merge.txt.tmp > $1.$2.merge.txt
printf " done!\n"

maxlines=$( wc -l $1.$2.merge.txt | awk '{ print $1 }' )
counter=1
notfoundtoinvalid=0
notfoundtovalid=0
invalidtovalid=0
invalidtonotfound=0

printf "Analyze data..."
while read -r column1 column2
do
    if [ "$column1" = "NotFound" -a "$column2" = "Invalid" ]
    then
        notfoundtoinvalid=$((notfoundtoinvalid+1))
    fi

    if [ "$column1" = "Invalid" -a "$column2" = "NotFound" ]
    then
        invalidtonotfound=$((invalidtonotfound+1))
    fi

    if [ "$column1" = "NotFound" -a "$column2" = "Valid" ]
    then
        notfoundtovalid=$((notfoundtovalid+1))
    fi

    if [ "$column1" = "Invalid" -a "$column2" = "Valid" ]
    then
        invalidtovalid=$((invalidtovalid+1))
    fi

    counter=$((counter+1))
    #echo "$column1 $column2"
    echo -ne "${counter}/${maxlines} lines processed.\r"

done < $1.$2.merge.txt

echo "Compared $1 with $2" > statistics.txt
echo "" >> statistics.txt
echo "Prefixes..." >> statistics.txt
echo "announced Invalid in $1 -> announced NotFound in $2: $invalidtonotfound" >> statistics.txt
echo "announced NotFound in $1 -> announced Invalid in $2: $notfoundtoinvalid" >> statistics.txt
echo "announced NotFound in $1 -> announced Valid in $2: $notfoundtovalid" >> statistics.txt
echo "announced Invalid in $1 -> announced Valid in $2: $invalidtovalid" >> statistics.txt
printf " \ndone!\n"

printf "Cleanup temp data..."
rm $1.short* $2.short* $1.$2.merge*
printf " done!\n"
