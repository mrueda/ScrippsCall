#!/usr/bin/env bash
#
#   STSI's Exome Pipeline -> Relatedness determination for families
#
#   Last Modified; Jul/23/2016
#
#   Version: 1.0.5
#
#   2016 Manuel Rueda (mrueda@scripps.edu)
#
#   Using bedtools jaccard implementation
#   

set -eu

export LC_ALL=C

# Check arguments
if [ $# -ne 0 ]
 then
  echo "$0"
  exit 1
fi

# Determine the directory where the script resides
BINDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source parameters.sh from the same directory
source "$BINDIR/parameters.sh"

dir=../../*_ex/*wes_single*/VARCALL/

for vcf1 in $( ls -1 $dir/*.*QC.vcf )
do
 short1=$( echo $vcf1 | awk -F'/' '{print $NF}' | sed 's/.ug.QC.vcf//' )
 for vcf2 in $( ls -1 $dir/*.*QC.vcf )
 do
  short2=$( echo $vcf2 | awk -F'/' '{print $NF}' | sed 's/.ug.QC.vcf//' )
  echo -n "$short1 $short2 "
  $BED jaccard -a $vcf1 -b $vcf2 | sed '1d' | cut -f3 | tr '\n' ' '
  echo
 done
done
