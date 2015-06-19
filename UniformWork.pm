package UniformWork;

use Moo;

has id         => ( is => 'ro' );
has capacity   => ( is => 'ro' );

has inventory  => ( is => 'rw', default => 0 );

has output_to  => ( is => 'rw' );
has input_from => ( is => 'rw' );

no Moo;

sub step {
    my $self = shift;
    my $capacity  = $self->capacity;

    # the one that doesn't get input gets random input from the 
    # environment
    unless ($self->input_from) {
        $self->receive_inventory( int( $capacity * rand() ) );
    }

    my $inventory = $self->inventory;

    my $serviced_this_time = int( $capacity * rand() );
    my $output = ($inventory > $serviced_this_time) ? $serviced_this_time : $inventory;
        
    $self->inventory( $inventory - $output );

    if ($self->output_to) {
        $self->output_to->receive_inventory( $output );
    }
    warn "Id:[". $self->id . "] has inventory of [". $self->inventory ."] at the end of the step;";
}

sub receive_inventory {
    my $self = shift;
    my $new_inventory = shift;
    $self->inventory( $self->inventory + $new_inventory );
}

1;
