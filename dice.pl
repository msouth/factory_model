use strict;
use warnings;


use UniformWork;

my @stations;
foreach my $id (1..3) {
    $stations[$id] = UniformWork->new( id=>$id, capacity=>6 );
}

foreach my $machine_id (1..3) {
    $stations[$machine_id]->input_from( $stations[$machine_id - 1] ) if $machine_id > 1;
    $stations[$machine_id]->output_to(  $stations[$machine_id + 1] ) if $machine_id < 3;
}

while (1) {
    foreach my $station (@stations) {
        next unless $station;
        $station->step();
        select undef, undef, undef, .5;
    }
}

