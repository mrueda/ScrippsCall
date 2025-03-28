# NAME

ScrippsCall: A framework for the analysis of Illumina's NGS data.

# SYNOPSIS

scrippscall -i &lt;config\_file> -t &lt;n\_threads> \[-options\]

     Arguments:
       -i|input                       Configuration file
       -t|threads                     Number of CPUs/Cores/Threads

     Options:
       -debug                         Print debugging (from 1 to 5, being 5 max)
       -h|help                        Brief help message
       -man                           Full documentation
       -v                             Version
       -verbose                       Verbosity on

# CITATION

Rueda et al. "Molecular Autopsy for Sudden Death in the Young: Is Data Aggregation the Key?" Front. Cardiovasc. Med., 09 November 2017 | https://doi.org/10.3389/fcvm.2017.00072

# SUMMARY

ScrippsCall is a framework for the analysis, annotation, filtering and reporting of NGS data coming from Illumina, Inc. sequencers. ScrippsCall was used to analyze WES data (including mtDNA) from all Molecular Autopsy and IDIOM cases at the Scripps Translational Science Institute (now SRTI).

# INSTALLATION

    git clone https://github.com/mrueda/ScrippsCall.git
    cd ScrippsCall
    sudo apt-get install cpanminus # Note we use sudo
    cpanm --notest --installdeps .

# HOW TO RUN SCRIPPSCALL

For executing ScrippsCall you will need:

- Input files

    A folder with Paired End fastq files (e.g., MA00001\_exome/MA0000101P\_ex/\*{R1,R2}\*fastq.gz).

- A Configuration (input) file

    A text file with the parameters that will control the job.

Below are parameters that can be modified by the user along with their default values. 
Pleave a blank space(s) or tab between the parameter and the value. 

Essential parameters

    * mode              single   
    * pipeline          wes             
    * sample            undef            

Optional parameters 

    * capture               Agilent SureSelect  # Not used
    * genome                hg19                # Not used
    * organism              Homo Sapiens        # Not used
    * technology            Illumina HiSeq      # Not used

ScrippsCall will create an independent project directory (scrippscall\_\*) and store all information needed there. Thus, many concurrent calculations are supported.

Note that ScrippsCall will not modify your original files.

Please find below a detailed description of the important parameters:

- **mode**

    ScrippsCall supports 2 modes, 'single' (default) and 'cohort' (for families or small cohorts).

- **pipeline**

    The pipeline to use. Currently we have 'wes' (whole exome) and 'mit' (mtDNA) implemented. Note that in order to run 'cohort' in 'mit|wes' first you need to run 'single wes' on each sample.

- **sample**

    The path (relative path is fine) to the directory where the fastq files for the sample are. See directory `examples` for more information.

**Examples:**

    $ bin/scrippscall -i config_file -t 8

    $ bin/scrippscall -i config_file -t 4 -verbose

    $ bin/scrippscall --i config_file -t 16 > log 2>&1

    $ $path_to_scrippscall/bin/scrippscall -i config_file -t 8 -debug 5

NB: In a Trio, the number of unique (de novo) variants for the proband should be ~ 1% and for the F, M ~ 10%. Deviations from this are suspicious.

# SYSTEM REQUIREMENTS

ScrippsCall runs on a multi-core Linux desktop/workstation/server. It's deliberate to stay away from HPC ;-) 

      * Ideally a Ubuntu-like distribution (Linux Mint >= 13 recommended).
      * >= 8GB of RAM.
      * 4 cores (ideally i7 or Xeon).
      * At least 250GB HDD.
      * Perl > 5.10 and Term::ANSIColor and JSON::XS CPAN Modules
      * All the files needed to run the WES pipeline (defined at variant_calling/parameters.sh).
        - Agile SureSelect for hg19.
        - Java 8: $sudo apt install openjdk-8-jdk.
        - GATK 3.5 and its bundle for hg19 (no longer available). b37 also works yet the capture was built for hg19 so VCF results may vary.
      * Optional => MToolBox L<https://github.com/mitoNGS/MToolBox> installed (if you want to get mtDNA analyzed).
        - You will need to have Python 2.7 installed and working: $ sudo apt install python2
        - C<pandas> in $PYTHONPATH env variable
      * Optional => SG-Adviser - At Scripps the annotation was performed with SG-Adviser L<https://genomics.scripps.edu/adviser>.
    

The Perl script itself does not require much RAM (with a maximum load of 2% on a 16GB system), but mapping operations benefit from larger memory allocations. GATK and Picard have a default RAM allocation of 8GB, which users can modify as needed.

The code is fully parallelized but doesn't scale linearly with `threads`. The sweet spot is 4 cores/threads. If you have 12 cores, running 3 jobs with 4 cores each may be better than one using all 12, though at the cost of slower I/O.

I am not using any CPAN's module to perform unit/integration test. Whenever I modified the code I make sure the csv/vcf match those in my test dir.

# COMMON ERRORS AND TREATMENT

    * GATK: wes_{single,cohort}.sh stops at "-GATK Recalibrator SNP" or "-GATK Recalibrator INDEL" step:
          - Error: MESSAGE: NaN LOD value assigned. Clustering with this few variants and these annotations is unsafe. Please consider raising the number of variants used to train the negative model (via --minNumBadVariants 5000, for example)
            This happened when nINDELs was < 8000. Most exomes will get ~ 5K. 5K is not enough for GATK. After trial and error we set the nINDEL = 8000. Still, it can fail.
            Solution: Increase the number of Indels to be included to > 8000 in wes_{single,cohort}.sh
            NB: In wes_single.sh, only re-reun the sample that fails.

         - Error: MESSAGE: Line 9999999: there aren't enough columns for line  /media/mrueda/2TB/genomes/GATK_bundle/hg19/dbsnp_137.hg19.vcf
           Solution: Eliminating that line from the file /media/mrueda/2TB/genomes/GATK_bundle/hg19/dbsnp_137.hg19.vcf.ori and fill a README.
    * MTOOLBOX:
          -  Fails:
             -  When UseIndelRealigner=true GATK fails every now and then and complains about unsupported N_CIGAR.
                Added line 386 to Mtoolbox.sh => --filter_reads_with_N_cigar
                If the issue persists try changing MToolbox_config.sh => UseIndelRealigner=false
          - If the DP < 10 the sample will not appear in Sample column
          - In cohort mode, the HF can vary with respect to single sample
             -  In general the concordance is very high, even when the DP is extremely different ( e.g., 2000 vs 100 in samples MA_56)
             -  If the coverage of sample is very low (like that for ID_46 that had 5x-10x the HF will become meaningless.

    * PERL: Some Linux distributions do not include the standard Perl library Pod::Usage. Please, install it if needed.

# AUTHOR

Written by Manuel Rueda, PhD.
The exome pipeline for Agilent SureSelect capture is an adaptation from that of _gfzhang_ for TSRI-HPC (2012).
Info about TSRI can be found at [http://www.tsri.edu](http://www.tsri.edu).

# REPORTING BUGS

Report bugs or comments to <mrueda@scripps.edu>.

# COPYRIGHT AND LICENSE

This PERL file is copyrighted, (C) 2015-2017 Manuel Rueda. See the LICENSE file included in this distribution.
