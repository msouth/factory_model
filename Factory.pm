package Factory;
use Const::Fast;

const my $READ => 0;
const my $WRITE => 1;
use Moo;

has work_stations => ( is => 'rw', default => sub {[]} );

no Moo;


sub add_work_station {
    my $self = shift;
    my %args = @_;
    my @output_to = @{$args{output_to} || []};
    my @input_from = @{$args{input_from} || []};
    pipe my $child_to_parent_reader, my $child_to_parent_writer;
    pipe my $parent_to_child_reader, my $parent_to_child_writer;
    #print "\n\n\n\n\nin add_ws, BEFORE new workstation, child to parent reader fileno is [". fileno(  $child_to_parent_reader ) . "]";
    my $ws = WorkStation->new( %args, call_mama=>[$child_to_parent_reader,$child_to_parent_writer], hear_mama=>[$parent_to_child_reader, $parent_to_child_writer] );
    #print "in add_ws, AFTER new workstation, child to parent reader fileno is [". fileno(  $child_to_parent_reader ) . "]\n\n\n\n\n";
    #NO!  closes for the child, too! close $child_to_parent_writer;
    #NO!  closes for the child, too! close $parent_to_child_reader;
    push @{ $self->work_stations }, $ws;
    return $ws;

}

sub start_work {
    my $self = shift;
    foreach my $ws (@{$self->work_stations}) {
        my $child_pid = fork;
        if ($child_pid) {
            $ws->process_id($child_pid);
        }
        else {
            $ws->process_id($child_pid);
            $ws->work;
            exit;
        }
    }
    $self->loop();
}

use Time::HiRes;
my ($start_sec,$start_musec) = Time::HiRes::gettimeofday;
my $sample_message = join '<|>', sprintf('%06d', '1'), $start_sec, sprintf('%06d',$start_musec), 'out', sprintf ('%06d', 1);
my $read_length = length( $sample_message );
sub loop {
    my $self = shift;
    my %ws_by_id;
    foreach my $ws (@{ $self->work_stations } ) {
        unless ($ws_by_id{ $ws->id }) {
            $ws_by_id{ $ws->id } = $ws;
        }
    }
        
    while (1) {
        foreach my $ws (@{ $self->work_stations } ) {
            # check for messages
            my $read_from_child = $ws->call_mama()->[$READ];
            my $write_from_child = $ws->call_mama()->[$WRITE];
            if (fileno( $write_from_child )) {
                close $write_from_child;
            }
            #die "fileno of read_from and write from are:". fileno($read_from_child) . ', '.fileno($write_from_child);
            # glob refs as expected die Dumper( $ws->call_mama() ); use Data::Dumper;
            my $rin='';
            die "I'm in [$$] and fileno(read_from_child) is undefined" unless defined fileno($read_from_child);

            vec($rin, fileno($read_from_child), 1) = 1;
            #my @messages = 0;
            my $thing; # part of the magic vec+select invocation...no idea
            while (select($thing=$rin,undef,undef,0)) {
                sysread($read_from_child, my $the_message, $read_length);
                if (length $the_message == $read_length) {
                    my ($id, $sec, $musec, $what, $count) = split '\Q<|>', $the_message;
                    #FIXME only sends to first output
                    if (my $id_to_send_to = $ws->output_to->[0]) {
                        my $ws_to_send_to = $ws_by_id{$id_to_send_to};
                        syswrite( $ws_to_send_to->hear_mama->[$WRITE], $the_message );
                        # tell the $ws that it has new input;
                    }
            #        push @messages, $the_message;
                    #warn __PACKAGE__.':  '. $the_message;
                    #warn "inventory on ws [". $ws->id . "] is ". $ws->inventory if $ws->input_from;
                }
                else {
                    #TODO at least warn dumper here so I can see how often and what happens
                }
            }

            # relay 
        }
    }
}

sub DEMOLISH {
    my $self = shift;
    # reap children
    foreach my $ws (@{ $self->work_stations }) {
        kill 2 => $ws->process_id if $ws->process_id;
    }
}

1;
