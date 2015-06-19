use warnings;
use strict;
pipe my $reader, my $writer;

#die Dumper( $reader ); use Data::Dumper;

if (fork) {
    print "in parent:  fileno(reader) = [".fileno($reader)."], fileno writer = [".fileno($writer)."]\n";
}
else {
    print "in child:  fileno(reader) = [".fileno($reader)."], fileno writer = [".fileno($writer)."]\n";
}
