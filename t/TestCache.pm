package TestCache;

use Storable qw( nfreeze thaw );

sub new {
    my $class = shift;

    my $self = {};

    bless $self, $class;

    return $self;
}

sub set {
    my $self  = shift;
    my $key   = shift;
    my $value = shift;    # an HTTP::Response

    my $res = thaw($value);
    $res->content("DUMMY");
    $self->{$key} = nfreeze($res);
}

sub get {
    my $self = shift;
    my $key  = shift;

    return $self->{$key};
}

1;
