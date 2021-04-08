#!/usr/bin/env perl
#
#   Script for parsing MToolbox prioritized_variants.txt to match VCF_file.tmp
#
#   Last Modified; Feb/08/2017
#
#   Version: 1.0.5
#
#   Copyright (C) 2017 Manuel Rueda (mrueda@scripps.edu)
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#   If this program helps you in your research, please cite.

use strict;
use warnings;

while (<>) {
    chomp;
    s/[A-Z]//g;
    s/\.//g;

    # Possibilites I've seen
    #    310.C => 310
    #    286-287d => 285
    #    8270-8278d => 8269
    #    Insertions keep the same numbering
    my $del = $_ =~ /d/ ? '1' : '0';
    s/[a-z]//g;    # getting rid of d
    my @tmp_fields = split /-/;
    my $var        = $tmp_fields[0] - $del;
    print "$var\n";
}
