#!/bin/bash
#
#   STSI's Coverage stats for chr1 Bash script.
#
#   Last Modified; April/26/2016
#
#   Version: 1.0.5
#
#   2016 Manuel Rueda (mrueda@scripps.edu)
#
#   Adapted from Torkamani's lab pipeline written by gfzhang somewhere ~ 2012
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

# Check arguments
if [ $# -ne 3 ]
 then
  echo "$0 id chr1.raw.bam chr1.dedup.bam"
  exit 1
fi

# Determine the directory where the script resides
BINDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source parameters.sh from the same directory
source "$BINDIR/parameters.sh"

chrN=chr1
REGION=$EXOM/hg19.$chrN.bed
EXOME_COORD=$EXOM/hg19_coor.$chrN.txt
sid=$1
RAWBAM=$2
DEDUPBAM=$3

# Calculate non-duplicate percentage
exon_span=$( awk '{span+=($3-$2)}END{print span}' $REGION )
dup_sum=$( $SAM depth -b $REGION $RAWBAM 2> /dev/null | awk '{sum+=$3}END{print sum}' )

# Calculate percentage of reads in chrN and out of chrN (exonic)
total_reads=$( $SAM idxstats $RAWBAM | awk '{s+=$3+$4} END {print s}' ) # Total in BAM
exome_reads=$( $SAM view $RAWBAM $(cat $EXOME_COORD) | wc -l ) 
let out_exome=$total_reads-$exome_reads
#echo "total_reads=$total_reads"
#echo "exome reads=$exome_reads"
#echo "out_exome=$out_exome"

# Calculate mean insert size of library (the sequence between adapters)
# NB: If $SAM not defined 'view' will become 'vim'
# NB2: Using Dedup
ins_size=$( $SAM view $RAWBAM | awk '$9>0&&$9<600{sum+=$9;cnt++}END{print sum/cnt}'  )

# Output stats for coverage, nonduplicates, and mean_insert_size
$SAM depth -b $REGION $DEDUPBAM | \
awk -v sid=$sid -v exon_span=$exon_span -v dup_sum=$dup_sum -v ins_size=$ins_size -v exome_reads=$exome_reads \
-v total_reads=$total_reads -v out_exome=$out_exome -v chrN=$chrN '
{depth_sum+=$3}
$3>=10{c10++}
END {
  depth=sprintf("%4.1f",depth_sum/exon_span)
  r10=sprintf("%4.1f",100*c10/exon_span)
  nondup=sprintf("%4.1f",100*depth_sum/dup_sum)
  read_exome=sprintf("%4.1f",100*exome_reads/total_reads)
  read_out=sprintf("%4.1f",100*out_exome/total_reads)
  print chrN;
  print "sampleID\tmean_coverage\tten_reads%\tnonduplicate%\tmean_insert_size\treads_in_exome%\treads_out_of_exome%";
  print sid "\t\t" depth "\t\t" r10 "\t\t" nondup "\t\t" ins_size "\t\t" read_exome "\t\t" read_out
}'
exit
# alternative method
#$PIC \
#    CollectInsertSizeMetrics \
#    TMP_DIR=$TMPDIR \
#    I=${sid}.chr1.dedup.bam O=${sid}.chr1.insert_size.txt \
#    H=${sid}.chr1.insert_hs.pdf VALIDATION_STRINGENCY=SILENT
#
#ins_size=$( grep '^MEDIAN_INSERT_SIZE' -A1 ${sid}.chr1.insert_size.txt | tail -n+2 |awk '{print $5}' )
