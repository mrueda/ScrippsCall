#!/bin/bash
#
#   Script for submitting SG-Adviser CNV jobs internally
#
#   Last Modified; July/14/2016
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
    echo "Usage: Script.sh cnv_file"
    exit 1
fi

if [[ $1 = *gz ]]; then
    echo "Sorry! cnv_file cant't be gzipped"
    exit 1
fi

user=mrueda
cnv_file=$1 # Path to input file 
# mounted dir via sshfs /mnt/sshfs/sga/ -> /gpfs/group/stsi/data/adviser_web/user
dir=/mnt/sshfs/sga/${user}_$$
sgadir=/gpfs/group/stsi/data/gerikson/CNV_pipeline/Old_Pipeline_1.0
remotedir=/gpfs/group/stsi/data/adviser_web/$user/${user}_$$  # Actual dir
script=sga_$$.sh
log=sga_$$.log

# Creating the job dir
mkdir $dir

# Creating the script
cat<<EOF>$script
#!/bin/bash

# Now we submit the job
$sgadir/qsub_start_CNV_pipeline.sh $remotedir $$.err $cnv_file
EOF

chmod +x $script

# Copying input file and csh script to gb
cp $cnv_file $dir
cp $script $dir

# The only way of getting this done is by changing w permissions by everyone
chmod -R 777 $dir

# Running the job by passwordless ssh
echo "Submitting the job for $$"
job_id=$( ssh sgadvise@garibaldi.scripps.edu $remotedir/$script |tail -1 )
echo "Job id: $job_id"
echo $cnv_file    > $log
echo "${user}_$$" >> $log
echo $dir         >> $log
echo $job_id      >> $log
