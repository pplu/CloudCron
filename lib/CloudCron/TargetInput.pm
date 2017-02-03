package CloudCron::TargetInput;
use Moose;
use JSON;

has command => (is => 'ro', isa => 'Str', required => 1);
has env     => (is => 'ro', isa => 'HashRef[Str]', required => 0, default => sub { {} });
has type    => (is => 'ro', isa => 'Str', required => 0, default => sub { 'shell' });

sub json {
    my $self = shift;
    return to_json({
        command => $self->command,
        env     => $self->env,
        type    => $self->type,
    });
}

__PACKAGE__->meta->make_immutable;
1;
