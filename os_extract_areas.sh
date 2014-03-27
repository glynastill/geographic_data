#!/bin/sh

ssconvert -S $1/Doc/Codelist.xls $1/Doc/Codelist_%s.csv > /dev/null 2>&1 

sed -e 's/$/,CTY/; s/|/,/g; /\(DET\)/d' -i $1/Doc/Codelist_CTY.csv
sed -e 's/$/,DIS/; s/|/,/g; /\(DET\)/d' -i $1/Doc/Codelist_DIS.csv
sed -e 's/$/,DIW/; s/|/,/g; /\(DET\)/d' -i $1/Doc/Codelist_DIW.csv
sed -e 's/$/,LBO/; s/|/,/g; /\(DET\)/d' -i $1/Doc/Codelist_LBO.csv
sed -e 's/$/,LBW/; s/|/,/g; /\(DET\)/d' -i $1/Doc/Codelist_LBW.csv
sed -e 's/$/,MTD/; s/|/,/g; /\(DET\)/d' -i $1/Doc/Codelist_MTD.csv
sed -e 's/$/,MTW/; s/|/,/g; /\(DET\)/d' -i $1/Doc/Codelist_MTW.csv
sed -e 's/$/,UTA/; s/|/,/g; /\(DET\)/d' -i $1/Doc/Codelist_UTA.csv
sed -e 's/$/,UTE/; s/|/,/g; /\(DET\)/d' -i $1/Doc/Codelist_UTE.csv
sed -e 's/$/,UTW/; s/|/,/g; /\(DET\)/d' -i $1/Doc/Codelist_UTW.csv