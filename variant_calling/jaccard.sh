#!/bin/bash
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
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, see <https://www.gnu.org/licenses/>.
#
#   If this program helps you in your research, please cite.

set -eu

#export TMPDIR=/media/mrueda/4TB/tmp
export LC_ALL=C

# Check arguments
if [ $# -ne 0 ]
 then
  echo "$0"
  exit 1
fi

bedtools=/pro/NGSutils/bedtools2/bin/bedtools
dir=../../*_ex/*wes_single*/VARCALL/

for vcf1 in $( ls -1 $dir/*.*QC.vcf )
do
 short1=$( echo $vcf1 | awk -F'/' '{print $NF}' | sed 's/.ug.QC.vcf//' )
 for vcf2 in $( ls -1 $dir/*.*QC.vcf )
 do
  short2=$( echo $vcf2 | awk -F'/' '{print $NF}' | sed 's/.ug.QC.vcf//' )
  echo -n "$short1 $short2 "
  $bedtools jaccard -a $vcf1 -b $vcf2 | sed '1d' | cut -f3 | tr '\n' ' '
  echo
 done
done
