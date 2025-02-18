#!/bin/bash
set -eu 

dir=/media/mrueda/2TBS/CNAG/Project_CBI_Call/
scrippscall=/media/mrueda/2TBS/CNAG/Project_CBI_Call/scrippscall/bin/scrippscall
ncpu=4

for dirname in MA99999_exome
do
 cd $dir/$dirname
 echo $dirname
  echo "...$dirname"
  cat<<EOF> $dirname.wes_cohort.in
mode            cohort
pipeline        wes
sample          $dir/$dirname
EOF

$scrippscall -n $ncpu -i $dirname.wes_cohort.in 
cd ..
done
