#!/bin/bash
set -eu 

dir=/media/mrueda/2TBS/CNAG/Project_CBI_Call/
scrippscall=/media/mrueda/2TBS/CNAG/Project_CBI_Call/scrippscall/bin/scrippscall
ncpu=12

for dirname in MA00001_exome
do
 cd $dir/$dirname
 echo $dirname
 for sample in MA*ex
 do
  echo "...$sample"
  cd $sample
  cat<<EOF>$sample.wes_single.in
mode            single
pipeline        wes
sample          $dir/$dirname/$sample
EOF
$scrippscall -t $ncpu -i $sample.wes_single.in > $sample.wes_single.log 2>&1
  cd ..
 done
cd ..
done
