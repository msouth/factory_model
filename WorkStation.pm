use strict;
use warnings;

use Math::Random;
use Time::HiRes;


package WorkStation;
use Moo;
use Const::Fast;

const my $READ => 0;
const my $WRITE => 1;

has id        => (is => 'ro');
has deviation => (is => 'ro');
has average   => (is => 'ro');
has process   => (
    is => 'ro',
    lazy => 1,
    builder => '_gimme_a_processor',
);
has inventory  => (is => 'rw', default=>0);
has call_mama  => (is => 'rw', lazy=> 1, trigger=>\&_set_up_writer);
has hear_mama  => (is => 'rw', lazy=> 1, trigger=>\&_set_up_reader);
has input_from => (is => 'rw', default=>sub {[]});
has output_to  => (is => 'rw', default=>sub {[]});
has process_id => (is => 'rw', );

no Moo;

sub _set_up_reader {
    my ($self, $new_value, $old_value) = @_;
    # we want the read end of the pipe, so we're closeing
    # the write end
    #NO DO NOT DO THIS IT CLOSES FOR THE PARENT close( $new_value->[$WRITE] );
}
sub _set_up_writer {
    my ($self, $new_value, $old_value) = @_;
    # we want the write end of the pipe, so we're closeing
    # the read end
    print "\n\n\nin set up writer:fileno on reader, writer: ". fileno( $new_value->[$READ]) . ', '. fileno( $new_value->[$WRITE] ), $/, $/, $/;
    #NO DO NOT DO THIS IT CLOSES FOR THE PARENT close( $new_value->[$READ] );
}

sub _gimme_a_processor {
    my $self = shift;
    return sub { 
        scalar Math::Random::random_normal(undef, $self->average, $self->deviation) 
    };
}

sub _do_after {
    my %args = @_;
    my $delay  = $args{delay};
    my $action = $args{action};
    select undef, undef, undef, $delay;
    $action->();
}

my ($start_sec, $start_musec) = Time::HiRes::gettimeofday;
my $sample_message = join '<|>', sprintf('%06d', '1'), $start_sec, sprintf('%06d',$start_musec), 'out', sprintf ('%06d', 1);
my $read_length = length( $sample_message );

sub work {
    my $self = shift;
    close $self->call_mama()->[$READ];
    close $self->hear_mama()->[$WRITE];
    die "I'm [$$] supposed to be running in the child" if $self->process_id;
    while (1) {
        #warn "here is an example of process():". $self->process->();
        my $rin='';
        my $read_from_parent = $self->hear_mama->[$READ];
        die "I'm in [$$] and fileno(read_from_parent) is undefined" unless defined fileno($read_from_parent);

        vec($rin, fileno($read_from_parent), 1) = 1;
        my @messages = 0;
        my $thing; # part of the magic vec+select invocation...no idea
        while (select($thing=$rin,undef,undef,0)) {
            sysread($read_from_parent, my $the_message, $read_length);
            my ($id, $sec, $musec, $what, $count) = split /\Q<|>/, $the_message;
            #warn "I am [". $self->id . "].  In the message, id is [$id], what is [$what], count is [$count] (message was [$the_message]";
            # we could check that it got to us correctly by checking that $id = $self->input_from;
            warn "what???? I got a message from $id but id is not in the self->input_from list [". join(' ', @{ $self->input_from }) unless grep {$id==$_} @{ $self->input_from };
            $self->inventory( $self->inventory() + $count );
            warn $self->id. ": adding [$count] to inventory, it is now: ". $self->inventory;
        }

        my $i_have_inputs = scalar @{ $self->input_from };
        if ($i_have_inputs) {
            if ( $self->inventory > 0 ) {
                $self->inventory( $self->inventory() - 1);
                _do_after( 
                    delay  => $self->process->(), 
                    action => sub { syswrite( $self->call_mama()->[$WRITE], $self->_output_one_item() ) },
                );
            }
            else {
                #TODO set a timer and track idle time!
                #LOTS of these warn "I [". $self->id ."] just had an idle event!";
            }
        }
        else {
            _do_after( 
                delay  => $self->process->(), 
                action => sub { syswrite( $self->call_mama()->[$WRITE], $self->_output_one_item() ) },
            );
        }
    }
}

sub _output_one_item {
    my $self = shift;
    my ($sec,$musec) = Time::HiRes::gettimeofday;
    my $line_to_write = join '<|>', sprintf('%06d', $self->id), $sec, sprintf('%06d',$musec), 'out', sprintf ('%06d', 1);
#    print __PACKAGE__. ": ". $line_to_write;
    return $line_to_write;
}

sub DEMOLISH {
    my $self = shift;
    close $_ for $self->call_mama()->[$WRITE] ;
}

1;
