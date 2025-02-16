package Config;

use strict;
use warnings;
use autodie;
use Cwd qw(abs_path);
use Sys::Hostname;
use File::Spec::Functions qw(catdir catfile);
use feature               qw(say);

=head1 NAME

    SCRIPPSCALL::Config - Package for Config subroutines

=head1 SYNOPSIS

  use SCRIPPSCALL::Config

=head1 DESCRIPTION


=head1 AUTHOR

Written by Manuel Rueda, PhD

=cut

=head1 METHODS

=cut

=head2 read_config_file

    About   : Subroutine that reads the configuration file
    Usage   : None             
    Args    : 

=cut

sub read_config_file {

    my $config_file      = shift;
    my $user             = $ENV{LOGNAME} || $ENV{USER} || getpwuid($<);
    my $scrippscall_data = catdir( $main::Bin, '../variant_calling' );

    # We load %config with the default values
    my %config = (

        mode             => 'single',    # cohort
        sample           => undef,
        pipeline         => 'wes',
        user             => $user,
        genome           => 'hg19',      # b37
        organism         => 'human',
        bash4parameters  => catfile( $scrippscall_data, 'parameters.sh' ),
        bash4_wes_single => catfile( $scrippscall_data, 'wes_single.sh' ),
        bash4_wes_cohort => catfile( $scrippscall_data, 'wes_cohort.sh' ),
        bash4_mit_single => catfile( $scrippscall_data, 'mit_single.sh' ),
        bash4_mit_cohort => catfile( $scrippscall_data, 'mit_cohort.sh' ),
        bash4coverage    => catfile( $scrippscall_data, 'coverage.sh' ),
        technology       => 'Illumina HiSeq',
        capture          => 'Agilent SureSelect'
    );

    # Reading config file
    open( my $config, '<', $config_file );
    while ( defined( my $line = <$config> ) ) {
        next if $line =~ /^\s*$/;    # skipping blank lines
        next if $line =~ /^\s*#/;    # skipping commented lines
        chomp $line;
        $line =~ s/#.*//;            # no comments
        $line =~ s/^\s+//;           # No leading white
        $line =~ s/\s+$//;           # No trailing white

        # Now we simplify naming. Forcing lower case for config name (not for value)
        my $regex = qr/^(\w+)\s+([\S\s]+)/;
        $line =~ m/$regex/;
        my ( $key, $value ) = ( lc($1), $2 );

        # Check user typos in config name
        my $config_syntax_ok = scalar grep { $_ eq $key } keys %config;    #Note scalar context
        die "Parameter '$key' does not exist (typo?)\n" if !$config_syntax_ok;
        $value = 'off'
          if ( lc($value) eq 'no'
            || lc($value) eq 'of'
            || lc($value) eq 'false' );                                    # For consistency
        $value = 'on' if ( lc($value) eq 'yes' || lc($value) eq 'true' );    # For consistency

        # Assignation to hash %config
        if ( $key eq 'sample' ) {
            $config{output} = $value;
            $config{$key} = abs_path($value);
        }
        else { $config{$key} = $value; }
    }
    close($config);

    # Below are a few internal configaters that do not have (or we don't allow for) default values
    $config{id}   = time . substr( "00000$$", -5 );
    $config{date} = localtime();
    $config{projectdir} =
        $config{sample} . '/'
      . 'scrippscall' . '_'
      . $config{pipeline} . '_'
      . $config{mode} . '_'
      . $config{id};    # User will make symbolic link to final folder
    my @tmp = split /\//, $config{sample};
    $config{output}   = $tmp[-1];
    $config{hostname} = hostname;
    $config{user}     = $user;
    chomp( my $ncpuhost = qx{/usr/bin/nproc} ) // 1;
    $config{ncpuhost} = 0 + $ncpuhost;                       # coercing it to be a number
    $config{ncpuless} = $ncpuhost > 1 ? $ncpuhost - 1 : 1;
    my $str_ncpuless = $config{ncpuless};                    # We copy it (otherwise it will get "stringified" below and printed with "" in log.json)
    $config{zip} =
      ( -x '/usr/bin/pigz' )
      ? "/usr/bin/pigz -p $str_ncpuless"
      : '/bin/gunzip';

    # Check if the bash files exist and have +x permission
    die "You don't have +x permission for Bash's"
      unless ( -x $config{bash4parameters}
        && -x $config{bash4_wes_single}
        && -x $config{bash4_wes_cohort}
        && -x $config{bash4_mit_single}
        && -x $config{bash4_mit_cohort}
        && -x $config{bash4coverage} );

    return wantarray ? %config : \%config;
}
1;
