package TestCache;

use Sereal qw(encode_sereal decode_sereal);

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

    my $res = decode_sereal($value);
    $res->content("DUMMY");
    $self->{$key} = encode_sereal($res);
}

sub get {
    my $self = shift;
    my $key  = shift;

    return $self->{$key};
}

1;
