#!/usr/bin/env perl
#
#   Script to read and filter SG-ADVISER annotations
#   The output can be HASH | JSON | JSON4HTML | TSV
#
#   Last Modified; Jan/24/2016
#
#   Version: 1.0.5
#
#   Copyright (C) 2017 Manuel Rueda (mrueda@scripps.edu)
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
#   If this program helps you in your research, please cite

use strict;
use warnings;
use autodie;
use FindBin qw($Bin);
use lib $Bin;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;
use JSON::XS;
use Text::CSV::Slurp;

# Defining a few variables
my $filein        = '';
my $debug         = 0;
my $denovo        = 0;
my $maf_cutoff    = 0.01;
my $hapmap_cutoff = 10;
my $man           = 0;
my $help          = 0;
my $format        = 'hash';
my $panel         = 'exome';
my $sga_dir       = $Bin;
my $panel_dir     = $sga_dir . 'panel/';

# Reading arguments
GetOptions(
    "input|i=s"  => \$filein,           # string
    "panel|p=s"  => \$panel,            # string
    "denovo"     => \$denovo,           # flag
    "maf=f"      => \$maf_cutoff,       # real
    "hapmap=i"   => \$hapmap_cutoff,    # real
    "format|f=s" => \$format,           # string
    'help|h'     => \$help,             # flag
    "man"        => \$man,              # flag
    "debug"      => \$debug             # flag
) or pod2usage(2);
pod2usage(1) if $help;
pod2usage( -exitval => 0, -verbose => 2 ) if $man;
pod2usage(1) if !$filein;

# Defining the file consisting of the gene list
my %gene_panel = (
    exome                 => undef,
    gendiag               => $panel_dir . 'gendiag_118.lst',    # 118 genes
    gencardio_cardiopathy => $panel_dir
      . 'gencardio_cardiopathy_all_146.lst',                    # 146 genes
    gencardio_congenital => $panel_dir
      . 'gencardio_congenital_heart.lst',                       # 159 genes
    gencardio_epilepsy => $panel_dir . 'gencardio_epilepsy.lst',    # 127 genes
    illumina           => $panel_dir
      . 'illumina.lst'
    , # 174 genes -> Cardiac disease + aneurysm (https://www.illumina.com/products/by-type/clinical-research-products/trusight-cardio.html)
    illuminaplus => $panel_dir
      . 'illuminaplus.lst' # 233 genes -> iIllumina + 25 missing from gendiag + SCN7A(knock-out mouse viable)..SCN11A
       # + LOX + GRK[4-5] + ADRBK2 + NOS3 + PSEN2 + Invitae Aortopathy + cardio/arrhy (-RYR1 (muscle)) + CDH2 (Circulation: Cardiovascular Genetics. 2017;10:e001605)
);
my $gene_lst_file = $gene_panel{$panel};

# Loading a Hash with the contents of gene_panel (if exists)
# $VAR1 = { 'BAG3' => 1, etc.}
my %hash_gene = ();
if ($gene_lst_file) {
    my @gene_panel = ();
    open my $fh_gl, '<', $gene_lst_file;
    while ( defined( my $line = <$fh_gl> ) ) {
        push @gene_panel, $line;
    }
    close $fh_gl;
    chomp @gene_panel;
    %hash_gene = map { $_, 1 } @gene_panel;
    @gene_panel = ();
}

# Defining the position of the fields in the header
my %sga_data_loc = (
    'Haplotype'                                  => 0,
    'Chromosome'                                 => 1,
    'Begin'                                      => 2,
    'End'                                        => 3,
    'VarType'                                    => 4,
    'Reference'                                  => 5,
    'Allele'                                     => 6,
    'Notes'                                      => 7,
    'Gene'                                       => 8,
    'Gene_Type'                                  => 9,
    'Location'                                   => 10,
    'Distance'                                   => 11,
    'Coding_Impact'                              => 12,
    'Protein_Pos'                                => 13,
    'Original_AA'                                => 14,
    'Allele_AA'                                  => 15,
    'Start~Stop_Dist'                            => 16,
    'Prop_Cons_Affected_Upstream'                => 17,
    'Prop_Cons_Affected_Downstream'              => 18,
    'Trunc_Prediction'                           => 19,
    'Conserved46way'                             => 20,
    'Conserved46wayPlacental'                    => 21,
    'Conserved46wayPrimates'                     => 22,
    'ASW_minallele'                              => 23,
    'CEU_minallele'                              => 24,
    'CHB_minallele'                              => 25,
    'CHD_minallele'                              => 26,
    'GIH_minallele'                              => 27,
    'JPT_minallele'                              => 28,
    'LWK_minallele'                              => 29,
    'MEX_minallele'                              => 30,
    'MKK_minallele'                              => 31,
    'TSI_minallele'                              => 32,
    'YRI_minallele'                              => 33,
    '1000GENOMES_AF'                             => 34,
    'WELLDERLY_AF325'                            => 35,
    'NHLBI'                                      => 36,
    'eQTL_genes'                                 => 37,
    'miRNA_BS_influenced'                        => 38,
    'miRNA_BS_impact'                            => 39,
    'miRNA_BS_direct'                            => 40,
    'miRNA_BS_deltaG'                            => 41,
    'miRNA_genomic'                              => 42,
    'miRNA_folding_deltaG'                       => 43,
    'miRNA_binding_deltaG'                       => 44,
    'miRNA_top_targets_changed'                  => 45,
    'Splice_Site_Pred'                           => 46,
    'Splicing_Prediction(MaxENT)'                => 47,
    'ESE_sites'                                  => 48,
    'ESS_sites'                                  => 49,
    'Protein_Impact_Prediction(Polyphen)'        => 50,
    'Protein_Impact_Probability(Polyphen)'       => 51,
    'Protein_Impact_Prediction(SIFT)'            => 52,
    'Protein_Impact_Score(SIFT)'                 => 53,
    'Protein_Domains'                            => 54,
    'Protein_Domains_Impact(LogRE)'              => 55,
    'Protein_Impact_Prediction(Condel)'          => 56,
    'Protein_Impact_Probability(Condel)'         => 57,
    'TF_Binding_Sites'                           => 58,
    'TFBS_deltaS'                                => 59,
    'omimGene_ID~omimGene_association'           => 60,
    'Protein_Domain_Gene_Ontology'               => 61,
    'dbSNP_ID'                                   => 62,
    'HGMD_Variant~PubMedID'                      => 63,
    'HGMD_Gene~disease_association'              => 64,
    'CLINVAR'                                    => 65,
    'Genetic_Association_Database~PubMedID'      => 66,
    'PharmGKB_Database~Drug'                     => 67,
    'Inheritance~Penetrance'                     => 68,
    'Severity~Treatability'                      => 69,
    'COSMIC_Variant~NumSamples'                  => 70,
    'COSMIC_Gene~NumSamples'                     => 71,
    'MSKCC_CancerGenes'                          => 72,
    'Atlas_Oncology'                             => 73,
    'Sanger_CancerGenes'                         => 74,
    'Sanger_Germline_CancerGenes'                => 75,
    'Sanger_network-informed_CancerGenes~Pval'   => 76,
    'SegDup_Region'                              => 77,
    'Gene_Symbol'                                => 78,
    'DrugBank'                                   => 79,
    'Reactome_Pathway'                           => 80,
    'Gene_Onotology'                             => 81,
    'Disease_Ontology'                           => 82,
    'ADVISER_Clinical~Disease_Entry~Explanation' => 83,
    'ADVISER_Research~Disease_Entry~Explanation' => 84,
    'HAPMAP_AF_MAX'            => 85,    # New field that will store new info
    '1000GENOMES_NHLBI_AF_MAX' => 86     # New field that will store new info
);

# Defining the keys to be reported in an array
my @keys2report =
  qw (Chromosome Begin End VarType Reference Allele Notes Gene Gene_Symbol Coding_Impact Protein_Pos Original_AA Allele_AA dbSNP_ID HGMD_Variant~PubMedID HGMD_Variant~PubMedID HGMD_Gene~disease_association CLINVAR ADVISER_Clinical~Disease_Entry~Explanation Splice_Site_Pred SegDup_Region 1000GENOMES_AF NHLBI omimGene_ID~omimGene_association HAPMAP_AF_MAX 1000GENOMES_NHLBI_AF_MAX);

# Regex to filter PASS variants
my $regex_pass = qr/"filter": "PASS"/;

# Regex to filter 00 variants in proband (proband comes first)
my $regex_proband = qr/"germline": "00/;

# Regex to keep variants according to impact
#   if ("Nonsynonymous" in line[code_ind] or "Frameshift" in line[code_ind] or "Nonsense" in line[code_ind] or "Frame" in line[code_ind] or "Splice_Site_Donor_Damaged" in line[splice_ind] or "Splice_Site_Acceptor_Damaged" in line[splice_ind]) and line[seg_ind]=="-" :
# Note that
my $regex_cod_impact = qr/Nonsynonymous|Frame|Nonsense/;
my $regex_spl_impact =
  qr/Splice_Site_Donor_Damaged|Splice_Site_Acceptor_Damaged/;

# Regex to filter denovo variants 01P-02M-03F
# NB1: chrX can get hemyzygous Proband Male: 11-01-00
# NB2: chrN can get homozygous by          : 11-00-01
# atorkamani had
#  if germ[0] == "01" and (germ[1] == "00" or germ[1]=="NN") and (germ[2] == "00" or germ[2]=="NN") and "PASS" in line[7]:
# he was replacing '.|X' by 'N'
my $regex_denovo =
  qr/"germline": "(01-[0X\.][0X\.]-[0X\.][0X\.]|11-01-00|11-00-01|11-00-00)/;

# We will not display these two
# Note that 5 may contain "~Uncertain significance" in -f85
# including ^4~not (specified|provided)~Likely benign (e.g. MA02005)
# Note that we filter by 'ADVISER_Research~Disease_Entry~Explanation' but that we'll display 'ADVISER_Clinical~Disease_Entry~Explanation'
my $regex_sga_five = qr/^5~not (specified|provided)~Benign/;

# Indexes for HapMap
my $hapmap_start = $sga_data_loc{'ASW_minallele'};
my $hapmap_end   = $sga_data_loc{'YRI_minallele'};

# The information about the variants will be stored in a Hash named %hash_out
my %hash_out = ();

###############################################
#  START READING AND PARSING SG_ADVISER FILE  #
###############################################
open my $fh_in, '<', $filein;
while ( defined( my $line = <$fh_in> ) ) {
    next if $. == 1;    # Skip header

# NB: DP only gets 1 value (the proband)
# 196   chr1    1119542 1119543 snp     G       C       {"filter": "PASS", "id": "01P-02M-03F-04K-05K", "germline": "01-00-01-00-00", "GQ": "99", "cov": "PASS", "geno": "--", "note": "rs74536858", "qual": "942.17", "DP": "44"}      TTLL10(uc001acy.2)///TTLL10(uc010nyg.1)///TTLL10(uc001acz.1)    Protein_Coding///Protein_Coding///Protein_Coding        Intron_12///Intron_12///Intron_8        0///0///0       -///-///-       -///-///-       -///-///-       -///-///-       -~-///-~-///-~- -///-///-       -///-///-       -///-///-       N/A~0.669       N/A~0.787       N/A~0.467       N/A     N/A     N/A     N/A     N/A     N/A     N/A     N/A     N/A     N/A     N/A     0.00641025641026        0.00771605      N/A     -       -///-///-       -///-///-       -       --      -       -       -       -///-///-       -///-///-       -       -       -///-///-       -///-///-       -///-///-       -///-///-       PF03133.8$PF08443.4///PF03133.8$PF08443.4///PF03133.8   -~-///-~-///-~- -///-///-       -///-///-       MA0155.1|INSM1|PLUS     -3.58277026659  -~-///-~-///-~- NULL///NULL///Molecular Function: tubulin-tyrosine ligase activity (GO:0004835)~Biological Process: protein modification process (GO:0006464)   rs74536858      RESTRICTED      -~-///-~-///-~- -~-~-~- -~-     -~-     -~-///-~-///-~- -~-///-~-///-~- -~-     haematopoietic_neoplasm$carcinoma~4///haematopoietic_neoplasm$carcinoma~4///haematopoietic_neoplasm$carcinoma~4 -///-///-       -///-///-       -///-///-       -///-///-       -~-///-~-///-~- -       TTLL10- -       GO:0018094~protein polyglycylation      -       -~-~-   -~-~-

    chomp $line;
    my @sga_fields = split /\t/, $line;
    my $index =
        $sga_fields[1] . '_'
      . $sga_fields[2] . '_'
      . $sga_fields[3] . '_'
      . $sga_fields[4] . '_'
      . $sga_fields[5] . '_'
      . $sga_fields[6];

    # When gene panel is activated skip lines w/o the genes on the list
    my $gene_exists = 0;
    if ($gene_lst_file) {
        my $genes_with_transcripts =
          $sga_fields[ $sga_data_loc{'Gene_Symbol'} ];
        my @genes_with_transcript_array = split /\/\/\//,
          $genes_with_transcripts;
        for my $tmp_gwt (@genes_with_transcript_array) {
            $gene_exists++ if exists $hash_gene{$tmp_gwt};
            print "####$gene_exists\n" if $debug;
        }
        next unless $gene_exists;
    }

    # Skip Non-PASS variants (equally fast as grepping it above)
    next unless $line =~ /$regex_pass/o;

    # Skip 00 in proband
    next if $line =~ /$regex_proband/o;

    ###########################################
    #  The section below includes our filters #
    ###########################################

    # Skip variants located in Segmental Duplications (values are [-|Seg_Dup|SegDup_Region])
    next unless $sga_fields[ $sga_data_loc{'SegDup_Region'} ] eq '-';

    # Skip lines w/o regex. Modifiers: -i-> ignore case -o: compiled once (2x faster)
    next
      unless (
        $sga_fields[ $sga_data_loc{'Coding_Impact'} ] =~ /$regex_cod_impact/io
        || $sga_fields[ $sga_data_loc{'Splice_Site_Pred'} ] =~
        /$regex_spl_impact/io );

    # Filter by number of minallele in HapMap populations
    my $hapmap_start    = $sga_data_loc{'ASW_minallele'};
    my $hapmap_end      = $sga_data_loc{'YRI_minallele'};
    my @hapmap_freqlist = @sga_fields[ $hapmap_start .. $hapmap_end ];
    @hapmap_freqlist =
      grep { $_ ne 'N/A' } @hapmap_freqlist;    # Getting rid of N/A

    # Reverse sorting to get the max as [0]
    @hapmap_freqlist = sort { $b <=> $a } @hapmap_freqlist;

    # If all values were N/A we will get an empty value
    my $hapmap_max = $hapmap_freqlist[0] // 'N/A';
    next unless ( $hapmap_max eq 'N/A' || $hapmap_max < $hapmap_cutoff );

    # Load new entry at array @sga_fields
    $sga_fields[ $sga_data_loc{'HAPMAP_AF_MAX'} ] =
      $hapmap_max ne 'N/A' ? $hapmap_max : 'N/A';

    # Filter by MAF freqs present in NHLBI and 1000G and NHLBI
    # Not using WELLDERLY_AF325 freqs
    # Fetching NHLBI (unique)
    my $NHLBI_freq = $sga_fields[ $sga_data_loc{'NHLBI'} ];

    # Fetching 1000G (unique or multiple)
    my $G1000_freq =
      $sga_fields[ $sga_data_loc{'1000GENOMES_AF'} ];    # To simplify naming

    # Filling an array
    my @G1000_freqlist = ();

    push( @G1000_freqlist, $NHLBI_freq ) if $NHLBI_freq ne 'N/A';
    push( @G1000_freqlist, ( split /~/, $G1000_freq ) )
      if $G1000_freq ne 'N/A';

    # Reverse sorting to get the max as [0]
    @G1000_freqlist = sort { $b <=> $a } @G1000_freqlist;
    my $G1000max = $G1000_freqlist[0] // 'N/A';
    next unless ( $G1000max eq 'N/A' || $G1000max < $maf_cutoff );

    # Load new entry at array @sga_fields
    $sga_fields[ $sga_data_loc{'1000GENOMES_NHLBI_AF_MAX'} ] =
      $G1000max ne 'N/A' ? sprintf( "%.4f", $G1000max ) : 'N/A';

    # Filter by ADVISER_Research~Disease_Entry~Explanation
    next
      if
      $sga_fields[ $sga_data_loc{'ADVISER_Research~Disease_Entry~Explanation'} ]
      =~ /$regex_sga_five/o;    # Excluding '5~not specified~Benign'

    # Filter by De-novo if argument -denovo is set
    if ($denovo) {
        my $germline = $sga_fields[ $sga_data_loc{Notes} ];
        $germline =~ /$regex_denovo/o;
        $germline =
          $1 ? "$1 | De-novo" : 'Nothing';    # Appending stuff to the string
        next unless $germline =~ /De-novo/;
        $hash_out{$index}{germline} = $germline;
    }

    # Those variants who passed all filters are loaded
    foreach my $key (@keys2report) {
        $hash_out{$index}{$key} = $sga_fields[ $sga_data_loc{$key} ];
    }

}
close $fh_in;

#############################################
#  END READING AND PARSING SG_ADVISER FILE  #
##############################################

#############################################
#  PRINTING ACCORDING TO USER PARAMETERS    #
#############################################

if ( $format eq 'hash' ) {
    $Data::Dumper::Sortkeys = 1;    # In alphabetic order
    print Dumper \%hash_out;
}

elsif ( $format eq 'json' ) {
    my $json = encode_json \%hash_out;    # No order
    print "$json\n";
}

elsif ( $format eq 'json4html' ) {
    my $array_ref = hash2array( \%hash_out );    # Ordered according to keys
    my $json      = encode_json $array_ref;
    $json =~ s/^/{"data":/;
    $json =~ s/$/\}/;
    print "$json\n";
}

elsif ( $format eq 'tsv' ) {

    # Text::CSV::Slurp only works with @AoH (not HoH)/ Note that we miss the 1D of the HoH.
    # NB1: keys (columns) will end up sorted naturally but rows will not
    # NB2: To sort by position | sort -t$'\t' -V -k8,8 -k6,6n
    my @array4tsv = map { $hash_out{$_} } keys %hash_out;
    my $tsv = 'None';
    if (scalar @array4tsv) {  # AoH needs to have elements otherwise error
        $tsv = Text::CSV::Slurp->create( input => \@array4tsv, sep_char => "\t" );
    }
    print "$tsv\n";
}

else {
    die "Unknown -f $format";
}


##################################################
#  END OF PRINTING ACCORDING TO USER PARAMETERS  #
##################################################

sub hash2array {

    # dataTables it's incredibly nitpicky
    my $hash_ref = shift;
    my @array    = ();       # Bidimensional array
    my $row      = 0;
    my $NA_str   = 'N/A';    # To clean the columns

    # Start looping
    for my $key1 ( keys %{$hash_ref} ) {

    #  qw (Chromosome Begin End VarType Reference Allele Gene Coding_Impact Protein_Pos dbSNP_ID HGMD_Variant~PubMedID HGMD_Gene~disease_association CLINVAR ADVISER_Clinical~Disease_Entry~Explanation Splice_Site_Pred SegDup_Region ASW_minallele YRI_minallele 1000GENOMES_AF NHLBI);
        my @keys4html =
          qw (Chromosome Begin End VarType Reference Allele Gene_Symbol Coding_Impact Protein_Pos dbSNP_ID 1000GENOMES_NHLBI_AF_MAX CLINVAR omimGene_ID~omimGene_association ADVISER_Clinical~Disease_Entry~Explanation Notes Gene);
        my $tmp_var = '';
        for my $key2 (@keys4html) {

            #for my $key2 ( sort keys $hash_ref->{$key1} ) {
            $tmp_var = $hash_ref->{$key1}{$key2};

            # Cleaning stuff
            #$tmp_var =~ s/\(.+\)// if $key2 eq 'Gene_Symbol';
            $tmp_var =~ s/-~-~-/$NA_str/
              if $key2 eq 'ADVISER_Clinical~Disease_Entry~Explanation';
            $tmp_var =~ s/-~-~-~-/$NA_str/ if $key2 eq 'CLINVAR';

            # Now we fix protein_field
            $tmp_var = parse_protein_string(
                $hash_ref->{$key1}{Protein_Pos},
                $hash_ref->{$key1}{Original_AA},
                $hash_ref->{$key1}{Allele_AA}
            ) if $key2 eq 'Protein_Pos';

            # Replacing values with URLs
            # http://exac.broadinstitute.org/region/10-88476311-88476312
            # http://exac.broadinstitute.org/variant/10-88476312-G-A
            if ( $key2 eq 'Chromosome' ) {
                my $exac_region =
"http://exac.broadinstitute.org/region/$hash_ref->{$key1}{Chromosome}-$hash_ref->{$key1}{Begin}-$hash_ref->{$key1}{End}";
                $tmp_var =~
s#$tmp_var#<a target="_blank" href="$exac_region">$tmp_var</a>#;
            }
            if ( $key2 eq 'End' ) {
                my $exac_variant =
"http://exac.broadinstitute.org/variant/$hash_ref->{$key1}{Chromosome}-$hash_ref->{$key1}{End}-$hash_ref->{$key1}{Reference}-$hash_ref->{$key1}{Allele}";
                $exac_variant =~ s#/variant/chr#/variant/#;
                $tmp_var =~
s#$tmp_var#<a target="_blank" href="$exac_variant">$tmp_var</a>#;
            }

            # Gene_Symbol  EYA4///AK093513
            if ( $key2 eq 'Gene_Symbol' ) {
                my $tmp_var_str = '';
                $tmp_var =~ s/\+//g;    #Na+/K+/Ca++ (href won't work otherwise)
                my @tmp_var_array = split /\/\/\//, $tmp_var;
                for my $tmp_var_array (@tmp_var_array) {
                    $tmp_var_array =~
s#$tmp_var_array#<a target="_blank" href="https://ghr.nlm.nih.gov/gene/$tmp_var_array\#conditions">$tmp_var_array</a>#;
                    $tmp_var_str .= $tmp_var_array . ',';
                }
                chop $tmp_var_str;      # Get rid of last comma
                $tmp_var = $tmp_var_str;
            }

            # dbSNP rs34403772///rs67538347
            if ( $key2 eq 'dbSNP_ID' ) {
                my $tmp_var_str = '';
                my @tmp_var_array = split /\/\/\//, $tmp_var;
                for my $tmp_var_array (@tmp_var_array) {
                    $tmp_var_array =~
s#$tmp_var_array#<a target="_blank" href="http://www.ncbi.nlm.nih.gov/projects/SNP/snp_ref.cgi?rs=$tmp_var_array">$tmp_var_array</a>#;
                    $tmp_var_str .= $tmp_var_array . ',';
                }
                chop $tmp_var_str;    # Get rid of last comma
                $tmp_var = $tmp_var_str;
            }

            # Parsing the "Notes" field
            if ( $key2 eq 'Notes' ) {

                # Trimming the beginning of the string
                # New files will have "id", but old files won't
                if ( $tmp_var !~ /"id"/ ) {
                    $tmp_var =~ s/^.+("germline")/$1/;
                }
                else {
                    $tmp_var =~ s/^.+("id")/\U$1/;    #\U uppercase
                }

                # Cutting from "GQ" to "DP"
                # "GQ": "99", "cov": "PASS", "geno": "--", "note": "rs117038725", "qual": "608.77", "DP": "61"}
                $tmp_var =~ s#"GQ".+"DP"#"DP"#;
                $tmp_var =~ s/germline/GT/;
                $tmp_var =~ s/"//g;                   # Getting rid of "
                chop $tmp_var;
            }
            push @{ $array[$row] }, $tmp_var;
        }
        $row++;
    }
    return \@array;
}

sub parse_protein_string {

    my $pos    = shift;
    my $prevAA = shift;
    my $newAA  = shift;

    my $str = '';

    # Multi-isoform
    if ( $pos =~ /\// ) {

        #my ($tmp_pos_str, $tmp_prev_str, $tmp_new_str) = ('') x 3;
        my %string   = ();
        my @tmp_pos  = split /\/\/\//, $pos;
        my @tmp_prev = split /\/\/\//, $prevAA;
        my @tmp_new  = split /\/\/\//, $newAA;
        for ( my $i = 0 ; $i <= $#tmp_pos ; $i++ ) {
            $string{"$i"} .= 'p.' . $tmp_prev[$i] . $tmp_pos[$i] . $tmp_new[$i];
        }
        for ( my $i = 0 ; $i <= $#tmp_pos ; $i++ ) {
            $str .= $string{"$i"} . '///';
        }
        $str =~ s/\/\/\/$//;
    }

    # single-isoform
    else {
        $str .= 'p.' . $prevAA . $pos . $newAA;
    }

    # p.-944-944- Frameshift may give warnings in perl
    $str =~ s/p\.---/./g;    # Cleaning empty annotations

    return $str;
}

=head1 NAME

sga2json: A script for parsing SG-Adviser output

=head1 SYNOPSIS

sga2json.pl -i sga_file.txt [-options]

     Arguments:                       
       -i|input                       SG-Adviser TSV file
       -p|panel                       Gene panel [>exome|gendiag|gencardio_cardiopathy|gencardio_congenital|gencardio_epilepsy|illumina|illuminaplus] 
       -f|format                      Output format [>hash|json|json4html|tsv]
       -denovo                        Denovo Mutations
       -maf                           maf filter [0.01] (we keep the variant if maximum MAF < maf value)
       -hapmap                        Hapmap filter [10 < alternate allele frequency of the variant in any Hapmap population]

     Options:
       -h|help                        Brief help message
       -man                           Full documentation
       -debug                         Print debugging (from 1 to 5, being 5 max)
