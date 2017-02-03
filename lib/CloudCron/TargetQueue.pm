package CloudCron::TargetQueue;
use Moose;
use namespace::autoclean;

has Arn => (is => 'ro', isa => 'Str', required => 1);
has Id  => (is => 'ro', isa => 'Str', required => 1);

__PACKAGE__->meta->make_immutable;
1;
