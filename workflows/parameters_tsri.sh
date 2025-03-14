# Version: 1.0.5
#
DATADIR=/media/mrueda/2TB
DBDIR=$DATADIR/Databases
NGSUTILS=/pro/NGSutils

# ENV
export TMPDIR=$DATADIR/tmp
export LC_ALL=C

MEM=4G
JAVA=/usr/bin/java
BWA=$NGSUTILS/bwa-0.7.17/bwa           # Needs ~6g RAM
SAM=$NGSUTILS/samtools-0.1.19/samtools # x4 faster than v1.3
PIC="$JAVA  -Xmx$MEM -Djava.io.tmpdir=$TMPDIR -jar $NGSUTILS/picard/build/libs/picard.jar"
GATK="$JAVA -Xmx$MEM -Djava.io.tmpdir=$TMPDIR -jar $NGSUTILS/gatk/3.5/GenomeAnalysisTK.jar"
#module load java/1.7.0_21

# GATK bundle, human genome hg19
BUNDLE=$DBDIR/genomes/GATK_bundle/hg19
REF=$BUNDLE/ucsc.hg19.fasta
REFGZ=$BUNDLE/ucsc.hg19.fasta.gz
dbSNP=$BUNDLE/dbsnp_137.hg19.vcf
MILLS_INDELS=$BUNDLE/Mills_and_1000G_gold_standard.indels.hg19.vcf
KG_INDELS=$BUNDLE/1000G_phase1.indels.hg19.vcf
HAPMAP=$BUNDLE/hapmap_3.3.hg19.vcf
OMNI=$BUNDLE/1000G_omni2.5.hg19.vcf

# training sets for variant recalibration
SNP_RES="-resource:hapmap,known=false,training=true,truth=true,prior=15.0 $HAPMAP \
         -resource:omni,known=false,training=true,truth=false,prior=12.0 $OMNI \
         -resource:dbsnp,known=true,training=false,truth=false,prior=6.0 $dbSNP "
INDEL_RES="-resource:mills,known=true,training=true,truth=true,prior=12.0 $MILLS_INDELS "

# Agilent SureSelect Whole Exome
EXOM=$DBDIR/genomes/Human_Exome/SureSelect
CHRLIST=$EXOM/hg19/bed/hg19.chr.list

# MuTecT
#MUT=/gpfs/group/stsi/methods/variant_calling/bwa_GATK/muTect

# parameters for UnifiedGenotyper
# down sampling, default=250
DCOV=1000
# call_conf,emit_conf, default=30
UG_CALL=50
UG_EMIT=10
#THREADS=4 # mrueda-> Now provided by external argument
