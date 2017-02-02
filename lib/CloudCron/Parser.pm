package CloudCron::Parser;
use Moose;
use namespace::autoclean;
use Parse::Crontab;

extends 'Parse::Crontab';

sub envs {
    my $self = shift;
    return grep { $_->isa('Parse::Crontab::Entry::Env') } $self->entries;
}

__PACKAGE__->meta->make_immutable;
1;
