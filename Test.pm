package Test;
use Moo;

has thing => (is => 'rw');

no Moo;

sub more_thing {
    my $self = shift;
    $self->thing( $self->thing() + 1 );
}

package main;

my $test = Test->new();

$test->thing( 10 );
$test->more_thing;

print $test->thing . ' is the final value of thing ', $/;
1;
