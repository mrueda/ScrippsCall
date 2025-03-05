#!/usr/bin/env bash
# 
#   STSI's mt-DNA Pipeline Bash script.
#   This pipeline works at the the sample level, for cohorts you will 
#   need to excute "mtdna_cohort.sh". This way, if a new relatives comes, 
#   you cand easily add it ia posteriori.
#
#   Last Modified; Oct/25/2016
#
#   Version: 1.0.5
#
#   2016 Manuel Rueda (mrueda@scripps.edu)
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

function usage {

    USAGE="""
    Usage: $0 -t n_threads

    NB1: The script is expecting that you follow STSI nomenclature for samples
    NB2: There is no need to run wes_cohort prior to mit_cohort.

MA00024_exome  <-- ID taken from here
├── MA0002401P_ex
│   └── scrippscall_wes_single_146723488708442
│       ├── BAM
│       ├── STATS
│       └── VARCALL
├── MA0002402M_ex
│   └── scrippscall_wes_single_146727114980481
│       ├── BAM
│       ├── STATS
│       └── VARCALL
├── MA0002402P_ex
│   └── scrippscall_wes_single_146730170886696
│       ├── BAM
│       ├── STATS
│       └── VARCALL
└── scrippscall_mit_cohort_146774466308431 <- The script expects that you are submitting the job from inside this directory
    """
    echo "$USAGE"
    exit 1
}


# Check arguments
if [ $# -eq 0 ]
 then
  usage
fi

# parsing Arguments
key="$1"
case $key in
    -t|--t)
    THREADS="$2"
esac


# Determine the directory where the script resides
BINDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source parameters.sh from the same directory
source "$BINDIR/parameters.sh"

# Set up variables and Defining directories
DIR=$( pwd )
BINDIRMTB=$BINDIR/../mtdna

# Check that nomenclature exists
if [[ $DIR != *scrippscall_mit_cohort* ]]
 then 
  usage
fi 

# The id need to have this format LP6005831-???_???.bam, otherwise MToolBox will fail
cohort=$( echo $DIR | awk -F'/' '{print $--NF}' | awk -F'_' '{print $1}' | sed 's/$/-DNA_MIT/')
echo $cohort

# From now on we will work on VARCALL dir
VARCALLDIR=$DIR/MTOOLBOX
mkdir $VARCALLDIR
cd $VARCALLDIR

# NB: We are using UCSC's hg19 for Exome.
# There are a few minor differences between GRCh37 and hg19. 
# The contig sequences are the same but the names are different, i.e. "1" may need to be converted to "chr1". 
# In addition UCSC hg19 is currenly using the old mitochondrial sequence but NCBI and Ensembl have transitioned to NC_012920.
# For using MttolBox we need to align again to RSRS

# Using Samtools to extract chrM
# NB: BAMs may include duplicated entries at this stage
echo "Extracting Mitochondrial DNA from exome BAM file..."
for BAMDIR in ../../??????????_ex/scrippscall_wes_single*/BAM
do
 id=$( echo $BAMDIR | awk -F'/' '{print $3}' | awk -F'_' '{print $1}' | sed 's/$/-DNA_MIT/')
 bam_raw=$BAMDIR/input.merged.bam.realigned.bam.fixed.bam
 out_raw=$id.bam

 # The index name must be foo.bam.bai instead of foo.bai (can happen if wes_single.sh failed)
 bam_raw_index=$BAMDIR/input.merged.bam.realigned.bam.fixed.bai
 bam_raw_index_ok=$BAMDIR/input.merged.bam.realigned.bam.fixed.bam.bai
 if [[ ! -s $bam_raw_index_ok ]]
  then
  cp $bam_raw_index $bam_raw_index_ok
 fi
 
 if [[ $REF == *b37*.fasta ]]
  then
   chrM=MT
 else
   chrM=chrM
 fi

 $SAM view -b $bam_raw $chrM > $out_raw
 $SAM index $out_raw
 
done

# Performing Variant calling and annotation with MToolBox
echo "Analyzing mitochondrial DNA with MToolBox..."
export PATH="$MTOOLBOXDIR:$PATH"

# Add the local site-packages to PYTHONPATH
export PYTHONPATH=~/.local/lib/python2.7/site-packages:${PYTHONPATH:-}

cp $BINDIRMTB/MToolBox_config.sh .
MToolBox.sh -i MToolBox_config.sh -m "-t $THREADS"

# We will be using the file 'prioritized_variants.txt'
# Getting GT/ DP and HF information rom VCF_file.vcf
# HF information is also in file(s) OUT*/*annotation.csv
# OUT* may contain > 1 *annotation (haplotypes), still the HF will be the same on each

# We will append the columns at the end
echo "Appending Heteroplasmic Fraction to the output..."
vcf_file=VCF_file.vcf
vcf_tmp=VCF_file_$$.vcf
in_file=prioritized_variants.txt
out_file=append_$$.txt
final_file=mit_prioritized_variants.txt
parse_var=$BINDIR/parse_var.pl
parse_prior=$BINDIR/parse_prioritized.pl
grep ^#CHROM $vcf_file > $vcf_tmp
for var in $(cut -f1 $in_file | sed '1d' | $parse_var) 
do
  grep -P "chrMT\t$var\t" $vcf_file >>  $vcf_tmp  || echo "$var not found"
done
$parse_prior -i $vcf_tmp > $out_file
paste $in_file $out_file > $final_file
rm $vcf_tmp $out_file

# Fin
echo "All done!!!"
exit 
