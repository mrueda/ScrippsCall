#!/bin/bash
#
#   STSI's Exome Cohort Pipeline Bash script.
#
#   Last Modified; July/14/2017
#
#   Version: 1.0.5
#
#   2016 Manuel Rueda (mrueda@scripps.edu)
#   Adapted from Torkamani's lab Exome pipeline written by gfzhang somewhere ~ 2012
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
    Usage: $0 -n n_cpu

    NB1: The script is expecting that you follow STSI nomenclature for samples

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
└── scrippscall_wes_cohort_146774466308431 <- The script expects that you are submitting the job from inside this directory
    ├── ANNOTATION
    └── VARCALL
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
    -n|--nt)
    THREADS="$2"
esac

# Determine the directory where the script resides
BINDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source parameters.sh from the same directory
source "$BINDIR/parameters.sh"

# Scripts to calculate miscellanea stats
JACCARD=$BINDIR/jaccard.sh

# Getting current location
DIR=$( pwd )

# Check that nomenclature exists
if [[ $DIR != *scrippscall_*cohort* ]]
 then 
  usage
fi

# Fetching the cohort id "MA00052"
# /media/mrueda/2TB/Project_MA/scrippscall/Project_MA/MA00052_exome/scrippscall_cohort_1234567890
# MA00052 <---
cohort=$( echo $DIR | awk -F'/' '{print $--NF}' | awk -F'_' '{print $1}' )
echo $cohort

# From now on we will work on VARCALL dir
VARCALLDIR=$DIR/VARCALL
STATSDIR=$DIR/STATS
mkdir $VARCALLDIR
mkdir $STATSDIR
cd $VARCALLDIR

# Create a log file with STDERR
LOG=$DIR/scrippscall_wes_cohort.log

# Now we split by chromosome to perform BQSR 
# GATK -L region -> allows for parallelization
for chr in {1..12} 1314 1516 1718 1920 2122XY  # This divisions are because of the format of Agilent's Sureselect BED files
do
 echo "---------------"
 echo "Chromosome...$chr" 

 REG=$EXOM/hg19.chr$chr.bed
 chrN=chr$chr

 ##################################
 #                                #
 #    VARIANT DISCOVERY           # 
 #                                #
 ##################################
 # GATK Variant Calling
 # UnifiedGenotyper x chr
 SSexome=$EXOM/hg19.chr$chr.flank100bp.bed
 
 echo "Creating string with multiple BAMs from cohort"
 # We append all inputs over the string tmp_in
 # NB: they MUST be  ../*_ex/scripps*/
 tmp_in=''
 for tmp_bam in  ../../??????????_ex/scrippscall_*/BAM/input.merged.bam.realigned.bam.fixed.bam.dedup.bam.$chrN.recal.bam
 do
  tmp_in="${tmp_in} -I $tmp_bam "
 done

 in=$tmp_in
 out=chr$chr.ug.raw.vcf
 echo "GATK UG"
 $GATK \
      -T UnifiedGenotyper \
      -R $REF \
      $in \
      -L $SSexome \
      --dbsnp $dbSNP \
      -o $out \
      -dcov $DCOV \
      -stand_call_conf $UG_CALL \
      -stand_emit_conf $UG_EMIT \
      -nt $THREADS \
      -glm BOTH 2> $LOG

 echo "Done with chr$chr!!"
done
echo "---------------"

# Now we merge all VCF's 
grep "#" chr1.ug.raw.vcf > header.txt
grep -hv '#'  chr*.ug.raw.vcf | awk '$1 !~ /_/' | sort -V | cat header.txt -  > $cohort.ug.raw.vcf # Keeping only chr{?,??}

# Variant Recalibrator
# http://gatkforums.broadinstitute.org/gatk/discussion/39/variant-quality-score-recalibration-vqsr
#       -nt $THREADS \  <== SLOWER
# VQSR does not perform well (if at all) on a single sample. 
# It can work with whole genome sequence, but if you're working with exome, there's just too few variants. 
# Our recommendation for dealing with this is to get additional sample bams from the 1000Genomes project and add them to your callset (see this presentation for details).
# Deleted "-std 10.0 -percentBad 0.12" as it not longer compatible with GATK 3.5

# SNP vcf VariantRecalibrator
echo "-GATK Recalibrator SNP"
$GATK \
      -T VariantRecalibrator \
      -R $REF \
      -input $cohort.ug.raw.vcf \
      -recalFile $cohort.ug.raw.snp.recal \
      -tranchesFile $cohort.ug.raw.snp.tranches \
      --maxGaussians 6 \
      $SNP_RES \
      -an QD -an HaplotypeScore -an MQRankSum -an ReadPosRankSum -an FS -an MQ \
      -mode SNP  2>> $LOG

# INDEL vcf VariantRecalibrator
echo "-GATK Recalibrator INDEL"
nINDEL=$( grep -v "#" $cohort.ug.raw.vcf| awk 'length($5) != 1'  | wc -l )
# If nINDEL < 8000 GATK's VariantRecalibrator complains
if [[ $nINDEL -gt 8000 ]]
  then
$GATK \
      -T VariantRecalibrator \
      -R $REF \
      -input $cohort.ug.raw.vcf \
      -recalFile $cohort.ug.raw.indel.recal \
      -tranchesFile $cohort.ug.raw.indel.tranches \
      --maxGaussians 4 \
      $INDEL_RES \
      -an QD -an FS -an ReadPosRankSum \
      -mode INDEL  2>> $LOG
else
  echo " >>>> No INDELs to recalibrate"
fi

# SNP vcf ApplyRecalibration
echo "-GATK Apply Recalibrator SNP"
$GATK \
      -T ApplyRecalibration \
      -R $REF \
      -input $cohort.ug.raw.vcf \
      -recalFile $cohort.ug.raw.snp.recal \
      -tranchesFile $cohort.ug.raw.snp.tranches \
      -o recalibratedSNPs.rawIndels.vcf \
      --ts_filter_level 99.0 \
      -mode SNP   2>> $LOG

# INDEL vcf ApplyRecalibration
echo "-GATK Apply Recalibrator INDEL"
if [ -s $cohort.ug.raw.indel.recal ]
  then
$GATK \
      -T ApplyRecalibration \
      -R $REF \
      -input recalibratedSNPs.rawIndels.vcf \
      -recalFile $cohort.ug.raw.indel.recal \
      -tranchesFile $cohort.ug.raw.indel.tranches \
      -o $cohort.ug.vqsr.vcf \
      --ts_filter_level 95.0 \
      -mode INDEL  2>> $LOG
else
  echo ">>>> No INDELs to recalibrate"
  cp recalibratedSNPs.rawIndels.vcf $cohort.ug.vqsr.vcf
fi

# VCF QC filtration
echo "-GATK Filter"
$GATK \
      -T VariantFiltration \
      -R $REF \
      -o $cohort.ug.QC.vcf \
      --variant $cohort.ug.vqsr.vcf \
      --clusterWindowSize 10 \
      --filterExpression "MQ0 >= 4 && ((MQ0 / (1.0 * DP)) > 0.1)" \
      --filterName "HARD_TO_VALIDATE" \
      --filterExpression "DP < 5 " \
      --filterName "LowCoverage" \
      --filterExpression "QUAL < 30.0 " \
      --filterName "VeryLowQual" \
      --filterExpression "QUAL > 30.0 && QUAL < 50.0 " \
      --filterName "LowQual" \
      --filterExpression "QD < 2.0 " \
      --filterName "LowQD" \
      --filterExpression "MQ < 40.0 " \
      --filterName "LowMQ" \
      --filterExpression "FS > 60.0 " \
      --filterName "StrandBias"  2>> $LOG

##################################
#                                #
#      JACCARD INDEX             # 
#                                #
##################################

cd $STATSDIR
$JACCARD > jaccard.txt
# Mother  - Father mean Jaccard is 0.45 +- 0.02
# Proband - Mother mean Jaccard is 0.60 +- 0.02
# Proband - Father mean Jaccard is 0.60 +- 0.01
# Proband - Kin    mean Jaccard is 0.57 +- 0.06
grep P jaccard.txt | awk '$NF < 0.5' > jaccard_lt50.txt

# Fin
echo "All done!!!"
exit 
