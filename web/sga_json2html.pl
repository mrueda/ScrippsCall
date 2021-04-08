#!/usr/bin/env perl
#
#   Script to transform SG-Adviser JSON to HTML
#
#   Last Modified; Jun/21/2016
#
#   Version: 1.0.5
#
#   Copyright (C) 2016 Manuel Rueda (mrueda@scripps.edu)
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

if ( @ARGV == 0 ) {
    print "Usage: $0 id\n";
    exit 1;
}

my $id      = $ARGV[0];
my $project = substr( $id, 0, 2 ) eq 'ID' ? 'IDIOM' : 'MOLECULAR AUTOPSY';
my $IP      = '137.131.64.63:81';
my $gencardio_cardiopathy = 146;
my $gencardio_congenital  = 159;
my $gencardio_epilepsy    = 127;
my $illuminaplus          = 233;
my $html = print_html( $id, $project, $IP, $gencardio_cardiopathy,
    $gencardio_congenital, $gencardio_epilepsy, $illuminaplus );
print $html;

sub print_html {
    my ( $id, $project, $IP, $gencardio_cardiopathy, $gencardio_congenital,
        $gencardio_epilepsy, $illuminaplus )
      = @_;
    my $str = <<EOF;
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>ScrippsCall Results Page</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="">
    <meta name="author" content="Manuel Rueda">
    

    <!-- Le styles -->
    <link rel="icon" href="http://$IP/img/favicon.ico" type="image/x-icon" />
    <link rel="stylesheet" type="text/css" href="http://$IP/css/bootstrap.css" rel="stylesheet">
    <link rel="stylesheet" type="text/css" href="http://$IP/css/bootstrap-responsive.css" rel="stylesheet">
    <link rel="stylesheet" type="text/css" href="http://$IP/css/main.css" rel="stylesheet">
    <link rel="stylesheet" type="text/css" href="http://$IP/jsD/media/css/jquery.dataTables.css">
    <link rel="stylesheet" type="text/css" href="http://$IP/jsD/media/css/dataTables.tableTools.css">
    <link rel="stylesheet" type="text/css" href="http://$IP/jsD/resources/syntax/shCore.css">
   
    <script src="http://$IP/js/jquery.min.js"></script>
    <script src="http://$IP/js/bootstrap.min.js"></script>
    <script src="http://$IP/js/main.js"></script>
    <script src="http://$IP/jsD/media/js/jquery.dataTables.min.js"></script>
    <script src="http://$IP/jsD/media/js/dataTables.tableTools.js"></script>
    <script src="http://$IP/jsD/media/js/resources/syntax/shCore.js"></script>
    <script src="http://$IP/jsD/media/js/resources/demo.js"></script>
    <script src="http://$IP/js/jqBootstrapValidation.js"></script>

   <script type="text/javascript" language="javascript" class="init">

   \$(document).ready(function() {
    \$('#table-panel-gencardio_cardiopathy').DataTable( {
        "ajax": "gencardio_cardiopathy.json",
        "search": {
          "regex": true
         },
        "order": [[ 13, "asc" ]],
     } );
   } );

   \$(document).ready(function() {
    \$('#table-panel-gencardio_congenital').DataTable( {
        "ajax": "gencardio_congenital.json",
        "search": {
          "regex": true
         },
        "order": [[ 13, "asc" ]],
     } );
   } );

   \$(document).ready(function() {
    \$('#table-panel-gencardio_epilepsy').DataTable( {
        "ajax": "gencardio_epilepsy.json",
        "search": {
          "regex": true
         },
        "order": [[ 13, "asc" ]],
     } );
   } );

   
   \$(document).ready(function() {
    \$('#table-panel-illuminaplus').DataTable( {
        "ajax": "illuminaplus.json",
        "search": {
          "regex": true
         },
        "order": [[ 13, "asc" ]],
     } );
   } );
   
   \$(document).ready(function() {
    \$('#table-panel-exome').DataTable( {
        "ajax": "exome.json",
        "search": {
          "regex": true
         },
        "bDeferRender": true,
        "order": [[ 13, "asc" ]],
     } );
   } );

   \$(document).ready(function() {
    \$('#table-panel-mit').DataTable( {
        "ajax": "mit.json",
        "search": {
          "regex": true
         },
        "bDeferRender": true,
        "order": [[ 8, "desc" ]],
     } );
   } );

   </script>


  </head>
  <body class="dt-example">

    <!-- NAVBAR
    ================================================== -->
    <div class="navbar navbar-inverse navbar-fixed-top">
            <div class="navbar-inner">
                <div class="container">
                    <a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                    </a>
                    <a class="brand">ScrippsCall: ALI-LAB</a>
                    <div class="nav-collapse collapse">
                        <ul class="nav">
                            <li><a href="http://$IP"><i class="icon-home icon-white"></i>Home</a></li>
                            <li class=""><a href="http://$IP/data/status.html">Status</a></li>
                            <li><a href="http://$IP/help.html">Help</a></li>
                            <li class="dropdown">
                                <a href="#" class="dropdown-toggle" data-toggle="dropdown">Links <b class="caret"></b></a>
                                <ul class="dropdown-menu">
                                    <li class="nav-header">Contact</li>
                                    <li><a href="mailto:mrueda\@scripps.edu">Author</a>
                                    <li class="divider"></li>
                                    <li class="nav-header">Corporate Info</li>
                                    <li><a href="http://scrippshealth.org">Scripps</a></li>
                                </ul>
                            </li>
                        </ul>
                    </div><!--/.nav-collapse -->
                </div>
            </div>
        </div>

      <div class="container">

     <a class="btn pull-right" href="#"><i class="icon-download"></i> VCF</a>
     <a class="btn pull-right" href="#"><i class="icon-download"></i> REPORT</a>
     <a class="btn pull-right" href="#"><i class="icon-download"></i> JOB SUMMARY</a>

     <h3>Job ID: $id &#9658 stsi</h3>
     <p><strong>::  $project </strong>:: NGS Bioinformatics Report<p>

      <div>

       <ul class="nav nav-tabs">
       <li class="active"><a href="#tab-panel-gencardio_cardiopathy" data-toggle="tab"> $gencardio_cardiopathy Genes - Panel Cardiopathy</a></li>
       <li><a href="#tab-panel-gencardio_congenital" data-toggle="tab">$gencardio_congenital  Genes - Panel Congenital heart</a></li>
       <li><a href="#tab-panel-gencardio_epilepsy" data-toggle="tab">$gencardio_epilepsy Genes - Panel Epilepsy</a></li>
       <li><a href="#tab-panel-illuminaplus" data-toggle="tab">$illuminaplus Genes - Panel Illumina+</a></li>
       <li><a href="#tab-panel-exome" data-toggle="tab">Exome</a></li>
       <li><a href="#tab-panel-mit" data-toggle="tab">mtDNA</a></li>

       </ul>

      <div id="myTabContent" class="tab-content">
      <!-- TABLE -->
      <div class="tab-pane fade in active" id="tab-panel-gencardio_cardiopathy">
      <!-- TABLE -->
      <table id="table-panel-gencardio_cardiopathy" class="display table table-hover table-condensed">
        <thead>
            <tr>
<th>Chr</th>
<th>Begin</th>
<th>End</th>
<th>Type</th>
<th>Ref</th>
<th>Alt</th>
<th>Gene</th>
<th>Impact</th>
<th>Protein</th>
<th>dbSNP</th>
<th>max_MAF</th>
<th>ClinVar</th>
<th>OMIM</th>
<th>SG-Adviser</th>
<th>Notes</th>
<th>Iso</th>
            </tr>
        </thead>
    </table>

      </div>
<!-- TABLE -->
      <div class="tab-pane fade in" id="tab-panel-gencardio_congenital">
      <!-- TABLE -->
      <table id="table-panel-gencardio_congenital" class="table table-hover table-condensed">
        <thead>
            <tr>
<th>Chr</th>
<th>Begin</th>
<th>End</th>
<th>Type</th>
<th>Ref</th>
<th>Alt</th>
<th>Gene</th>
<th>Impact</th>
<th>Protein</th>
<th>dbSNP</th>
<th>max_MAF</th>
<th>ClinVar</th>
<th>OMIM</th>
<th>SG-Adviser</th>
<th>Notes</th>
<th>Iso</th>
            </tr>
        </thead>
    </table>

      </div>
<!-- TABLE -->
      <div class="tab-pane fade in" id="tab-panel-gencardio_epilepsy">
      <!-- TABLE -->
      <table id="table-panel-gencardio_epilepsy" class="table table-hover table-condensed">
        <thead>
            <tr>
<th>Chr</th>
<th>Begin</th>
<th>End</th>
<th>Type</th>
<th>Ref</th>
<th>Alt</th>
<th>Gene</th>
<th>Impact</th>
<th>Protein</th>
<th>dbSNP</th>
<th>max_MAF</th>
<th>ClinVar</th>
<th>OMIM</th>
<th>SG-Adviser</th>
<th>Notes</th>
<th>Iso</th>
            </tr>
        </thead>
    </table>

      </div>

<!-- TABLE -->
      <div class="tab-pane fade in" id="tab-panel-illuminaplus">
      <!-- TABLE -->
      <table id="table-panel-illuminaplus" class="display table table-hover table-condensed">
        <thead>
            <tr>
<th>Chr</th>
<th>Begin</th>
<th>End</th>
<th>Type</th>
<th>Ref</th>
<th>Alt</th>
<th>Gene</th>
<th>Impact</th>
<th>Protein</th>
<th>dbSNP</th>
<th>max_MAF</th>
<th>ClinVar</th>
<th>OMIM</th>
<th>SG-Adviser</th>
<th>Notes</th>
<th>Iso</th>
            </tr>
        </thead>
    </table>

      </div>
<!-- TABLE -->
      <div class="tab-pane fade in" id="tab-panel-exome">
      <!-- TABLE -->
      <table id="table-panel-exome" class="display table table-hover table-condensed">
        <thead>
            <tr>
<th>Chr</th>
<th>Begin</th>
<th>End</th>
<th>Type</th>
<th>Ref</th>
<th>Alt</th>
<th>Gene</th>
<th>Impact</th>
<th>Protein</th>
<th>dbSNP</th>
<th>max_MAF</th>
<th>ClinVar</th>
<th>OMIM</th>
<th>SG-Adviser</th>
<th>Notes</th>
<th>Iso</th>
            </tr>
        </thead>
    </table>

      </div>

<!-- TABLE -->
      <div class="tab-pane fade in" id="tab-panel-mit">
      <!-- TABLE -->
      <table id="table-panel-mit" class="display table table-hover table-condensed">
        <thead>
            <tr>
<th>Sample</th>
<th>Locus</th>
<th>Variant_Allele</th>
<th>Ref</th>
<th>Alt</th>
<th>Aa_Change</th>
<th>GT</th>
<th>Depth</th>
<th>Heterop_Frac</th>
<th>tRNA_Annotation</th>
<th>Disease_Score</th>
<th>RNA_predictions</th>
<th>Mitomap_Associated_Disease(s)</th>
<th>Mitomap_Homoplasmy</th>
<th>Mitomap_Heteroplasmy</th>
<th>ClinVar</th>
<th>OMIM_link</th>
<th>dbSNP_ID</th>
<th>Mamit-tRNA_link</th>
<th>AC/AN_1000G</th>
<th>1000G_Homoplasmy</th>
<th>1000G_Heteroplasmy</th>
            </tr>
        </thead>
    </table>

      </div>
      </div>
      </div>
      <br /><p class="pagination-centered">CLINICAL AND GENETIC COUNSELING SERVICE OF RISK OF SUDDEN DEATH</p> 
      <hr>
      <!-- FOOTER -->
      <footer>
                    <p>&copy; 2016  Scripps Research | U.S.A.</p>

      </footer>

    </div><!-- /.container -->

  </body>
</html>
EOF
    return $str;
}
