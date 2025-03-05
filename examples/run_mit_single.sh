#!/bin/bash
set -eu 

dir=/media/mrueda/2TBS/CNAG/Project_CBI_Call/
scrippscall=/media/mrueda/2TBS/CNAG/Project_CBI_Call/scrippscall/bin/scrippscall
ncpu=4

for dirname in MA99999_exome
do
 cd $dir/$dirname
 echo $dirname
 for sample in MA*ex
 do
  echo "...$sample"
  cd $sample
  cat<<EOF>$sample.mit_single.in
mode            single
pipeline        mit
sample          $dir/$dirname/$sample
EOF
$scrippscall -t $ncpu -i $sample.mit_single.in > $sample.mit_single.log 2>&1
  cd ..
 done
cd ..
done
