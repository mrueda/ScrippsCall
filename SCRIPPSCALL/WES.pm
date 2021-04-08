package WES;

use strict;
use warnings;
use feature qw(say);

=head1 NAME

    SCRIPPSCALL::WES

=head1 SYNOPSIS

  use SCRIPPSCALL::WES

=head1 DESCRIPTION
 
  To do

=head1 AUTHOR

Written by Manuel Rueda, PhD

=cut

=head1 METHODS

=cut

=head2 new

    About   : 
    Usage   : None             
    Args    : 

=cut

sub new {

    my ( $class, $arg_sub ) = @_;
    my $self = {
        pipeline         => $arg_sub->{pipeline},
        mode             => $arg_sub->{mode},
        sample           => $arg_sub->{sample},
        ncpu             => $arg_sub->{ncpu},
        projectdir       => $arg_sub->{projectdir},
        bash4_mit_cohort => $arg_sub->{bash4_mit_cohort},
        bash4_mit_single => $arg_sub->{bash4_mit_single},
        bash4_wes_cohort => $arg_sub->{bash4_wes_cohort},
        bash4_wes_single => $arg_sub->{bash4_wes_single}

    };
    bless $self, $class;
    return $self;
}

=head2 variant_calling

    About   : Subroutine that sends the actual BASH pipeline
    Usage   : None             
    Args    : 

=cut

sub variant_calling {

    my ($self)   = @_;
    my $pipeline = $self->{pipeline};
    my $mode     = $self->{mode};
    my $dir      = $self->{projectdir};
    my $ncpu     = $self->{ncpu};
    my $bash_str = 'bash4_' . $pipeline . '_' . $mode;
    my $bash     = $self->{$bash_str};
    my $log      = $bash_str . '.log';
    my $cmd      = "cd $dir; $bash -n $ncpu > $log 2>&1";
    submit_cmd($cmd);
    return 1;
}

=head2 submit_cmd
    
    About   : Subroutine that sends systems calls
    Usage   : None             
    Args    : 
    
=cut

sub submit_cmd {

    my $cmd = shift;
    system("$cmd") == 0 or die("failed to execute: $!\n");
}

1;
