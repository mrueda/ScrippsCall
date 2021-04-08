#!/bin/bash
#
#   Script for submitting SG-Adviser jobs internally
#
#   Last Modified; April/26/2016
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

if [ $# -eq 0 ]; then
    echo "Usage: script.sh vcf_file"
    exit 1
fi

if [[ $1 = *gz ]]; then
    echo "Sorry! vcf cant't be gzipped"
    exit 1
fi

user=mrueda
vcf_file=$1 # Path to input file 
vcf_name=$( basename $vcf_file ) # Name of the file only
var_file=${vcf_name/vcf/vars}    # Name for the vars file created by vcf.to.pipeline.py
# mounted dir via sshfs /mnt/sshfs/sga/ -> /gpfs/group/stsi/data/adviser_web/user
dir=/mnt/sshfs/sga/${user}_$$
remotedir=/gpfs/group/stsi/data/adviser_web/$user/${user}_$$  # Actual dir
sgadir=/gpfs/group/stsi/methods/annotation/sg-adviser/production
script=sga_$$.csh
log=sga_$$.log

# Creating the job dir
mkdir $dir

# Creating the Script that sgadvise will use to submit the job
# NB1: According to gerikson, your user must be in MySQL DB to get HGMD and AGMD columns.
#      It did not work for HGMD (column 64) so I patched??? 
#      /gpfs/group/stsi/methods/annotation/sg-adviser/production/website/Human_Variation_Impact_Functions_website.py
# NB2: qsub_start_pipeline.csh works with VARS and VCF files
# If you want to KEEP the "Note" field then use VARS
# If you use VCF files some geno field will be overwritten

# Getting the Sample id while in BASH to simplify sed syntax below
# (SG-ADVISER script is in CSH)
# 01P-02M-03F etc.
str_id=$( head -1000 $vcf_file |grep '^#CHR' |cut -f10- | xargs -n1 |cut -c8-10  | sed 's/ /-/g' |xargs -n99 | sed 's/ /-/g' )
echo "Samples: $str_id"

# Creating the script
cat<<EOF>$script
#!/bin/csh
source $sgadir/sga_environ.sh

# We want to include GT column
python $sgadir/vcf.to.pipeline.py -f $remotedir/$vcf_name -gt 9

# Before submitting the job we hardcode the IDs in the "Notes" field
sed -e 's/"germline"/"id": "$str_id", "germline"/' $remotedir/$var_file > $remotedir/$var_file.$$
mv $remotedir/$var_file.$$ $remotedir/$var_file

# Now we submit the job
$sgadir/website/qsub_start_pipeline.csh $remotedir $$.err $var_file
EOF

chmod +x $script

# Copying input file and csh script to gb
cp $vcf_file $dir
cp $script $dir

# The only way of getting this done is by changing w permissions by everyone
chmod -R 777 $dir

# Running the job by passwordless ssh
echo "Submitting the job for $$"
job_id=$( ssh sgadvise@garibaldi.scripps.edu $remotedir/$script |tail -1 )
echo "Job id: $job_id"
echo $vcf_file    > $log
echo "${user}_$$" >> $log
echo $dir         >> $log
echo $job_id      >> $log
