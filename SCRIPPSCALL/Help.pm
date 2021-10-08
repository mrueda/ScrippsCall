package Help;

use strict;
use warnings;
use feature qw(say);
use Pod::Usage;
use Getopt::Long;

=head1 NAME

    SCRIPPSCALL::Help - Help file for the SCRIPPSCALL script

=head1 SYNOPSIS

  use SCRIPPSCALL::Help

=head1 DESCRIPTION


=head1 AUTHOR

Written by Manuel Rueda, PhD

=cut

=head1 METHODS

=cut

=head2 usage

    About   : Subroutine that parses the arguments
    Usage   : None             
    Args    : 

=cut

sub usage {

    # http://www.gsp.com/cgi-bin/man.cgi?section=3&topic=Getopt::Long
    my $version = shift;
    my %arg     = ();
    GetOptions(
        'v'         => sub { print "$version\n"; exit },
        'debug=i'   => \$arg{debug},        # numeric (integer)
        'v'         => \$arg{version},      # flag
        'verbose'   => \$arg{verbose},      # flag
        'h|help'    => \$arg{help},         # flag
        'man'       => \$arg{man},          # flag
        'n=i'       => \$arg{ncpu},         # numeric (integer)
        'i|input=s' => \$arg{configfile}    # string (-i as in AMBER MD package)

    ) or pod2usage( -exitval => 0, -verbose => 1 );

    # Control check
    pod2usage( -exitval => 0, -verbose => 2 ) if $arg{man};
    pod2usage( -exitval => 0, -verbose => 1 ) if $arg{help};
    pod2usage( -exitval => 1, -verbose => 1 )
      if ( !$arg{ncpu} || !$arg{configfile} );
    pod2usage(
        -exitval => 1,
        -verbose => 1,
        -message => 'Option --i requires a config_file'
    ) if ( !-s $arg{configfile} );
    pod2usage(
        -exitval => 1,
        -verbose => 1,
        -message => 'Option --n requires a positive integer'
    ) if ( $arg{ncpu} <= 0 );    # Must be positive integer

    # Initialize undefs
    $arg{debug} = 0 if !$arg{debug};
    return wantarray ? %arg : \%arg;
}

package GoodBye;

sub new {
    my $class = shift;
    return bless {}, $class;
}

=head2 goodbye

    About   : Well, the name says it all :-)
    Usage   :         
    Args    : 

=cut

sub say_goodbye {

    my @words = ( <<"EOF" =~ m/^\s*(.+)/gm );
      Aavjo
      Abar Dekha-Hobe
      Adeus
      Adios
      Aloha
      Alvida
      Ambera
      Annyong hi Kashipshio
      Arrivederci
      Auf Wiedersehen
      Au Revoir
      Ba'adan Mibinamet
      Dasvidania
      Donadagohvi
      Do Pobatchenya
      Do Widzenia
      Eyvallah
      Farvel
      Ha Det
      Hamba Kahle
      Hooroo
      Hwyl
      Kan Ga Waanaa
      Khuda Hafiz
      Kwa Heri
      La Revedere
      Le Hitra Ot
      Ma'as Salaam
      Mikonan
      Na-Shledanou
      Ni Sa Moce
      Paalam
      Rhonanai
      Sawatdi
      Sayonara
      Selavu
      Shalom
      Totsiens
      Tot Ziens
      Ukudigada
      Vale
      Zai Geen
      Zai Jian
      Zay Gesunt
EOF
    my $random_word = $words[ rand @words ];
    return $random_word;
}
1;
