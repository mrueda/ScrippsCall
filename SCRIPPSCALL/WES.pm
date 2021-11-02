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

    # Changes in $self performed at main
    my ( $class, $self ) = @_;
    bless $self, $class;
    return $self;
}

=head2 variant_calling

    About   : Subroutine that sends the actual BASH pipeline
    Usage   : None             
    Args    : 

=cut

sub variant_calling {

    my $self   = shift;
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
    return 1;
}
1;
