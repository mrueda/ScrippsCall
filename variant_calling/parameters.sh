# Version: 1.0.5
#

DATADIR=/media/mrueda/2TBS
DBDIR=$DATADIR/Databases
NGSUTILS=$DATADIR/NGSutils

# ENV
export TMPDIR=$DATADIR/tmp
export LC_ALL=C

MEM=4G
ARCH=$(uname -m)  
#JAVA=/usr/bin/java # Java 9
#module load java/1.7.0_21

if [ "$ARCH" == "aarch64" ]; then
    JAVA=/usr/lib/jvm/java-8-openjdk-arm64/bin/java
    BWA=$NGSUTILS/bwa-0.7.18_arm64/bwa           # Needs ~6g RAM
    SAM=$NGSUTILS/samtools-0.1.19_arm64/samtools # x4 faster than v1.3
else
    JAVA=/usr/lib/jvm/java-8-openjdk-amd64/bin/java
    BWA=$NGSUTILS/bwa-0.7.17/bwa           # Needs ~6g RAM
    SAM=$NGSUTILS/samtools-0.1.19/samtools # x4 faster than v1.3
fi

PIC="$JAVA  -Xmx$MEM -Djava.io.tmpdir=$TMPDIR -jar $NGSUTILS/picard/build/libs/picard.jar"
GATK="$JAVA -Xmx$MEM -Djava.io.tmpdir=$TMPDIR -Dgatk.report.telemetry=false -jar $NGSUTILS/gatk/3.5/GenomeAnalysisTK.jar"
MTOOLBOXDIR=$NGSUTILS/MToolBox-master/MToolBox

# GATK bundle, human genome hg19
bundle=$DBDIR/GATK_bundle/b37
REF=$bundle/references_b37_Homo_sapiens_assembly19.fasta
REFGZ=$bundle/references_b37_Homo_sapiens_assembly19.fasta.gz
dbSNP=$DBDIR/dbSNP/human_9606_b144_GRCh37p13/All_20160408.vcf.gz
MILLS_INDELS=$bundle/b37_Mills_and_1000G_gold_standard.indels.b37.vcf.gz
KG_INDELS=$bundle/b37_1000G_phase1.indels.b37.vcf.gz
HAPMAP=$bundle/b37_hapmap_3.3.b37.vcf.gz
OMNI=$bundle/b37_1000G_omni2.5.b37.vcf.gz

# training sets for variant recalibration
SNP_RES="-resource:hapmap,known=false,training=true,truth=true,prior=15.0 $HAPMAP \
         -resource:omni,known=false,training=true,truth=false,prior=12.0 $OMNI \
         -resource:dbsnp,known=true,training=false,truth=false,prior=6.0 $dbSNP "
INDEL_RES="-resource:mills,known=true,training=true,truth=true,prior=12.0 $MILLS_INDELS "

# Agilent SureSelect Whole Exome
EXOM=$DBDIR/Agilent_SureSelect/hg19/bed

# parameters for UnifiedGenotyper
# down sampling, default=250
DCOV=1000
# call_conf,emit_conf, default=30
UG_CALL=50
UG_EMIT=10
#THREADS=4 # mrueda-> Now provided by external argument
