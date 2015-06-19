use WorkStation;
use Factory;

use v5.14;

my $factory = Factory->new();

#print "srand for this run is ".srand()."\n";
#srand(1170799822);

Math::Random::random_set_seed_from_phrase('brad wanted me to test this');

my $step_one = $factory->add_work_station( id=> '1', output_to  => ['2'], deviation=>.5, average=>1 );
my $step_two = $factory->add_work_station( id=> '2', input_from => ['1'], deviation=>.5, average=>1 );
#print " this is the call_mama returned from add_work_station: " . Dumper( $ws->call_mama ); use Data::Dumper;
#print "reader fileno is ". fileno( $ws->call_mama()->[0] ), $/;
#print "writer fileno is ". fileno( $ws->call_mama()->[1] ), $/;
#print join '<>', map {fileno $_} @{ $ws->call_mama  }, "\n";

#warn "Starting work from [$$]";

$factory->start_work();
1;
