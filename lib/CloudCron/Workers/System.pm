package CloudCron::Workers::System;
use Moose;
use namespace::autoclean;
use CloudCron::TargetInput;

with 'SQS::Worker', 'SQS::Worker::DecodeJson';

sub process_message {
    my ($self, $message) = @_;
    my $cmd = $self->_parse_message($message);
    eval {
        my $exit = system($cmd->command);
    };
    warn $@ if $@;
};

sub _parse_message {
    my ($self, $message) = @_;
    return $message->Body;

    # return CloudCron::TargetInput->new(
    #     command => $message->command,
    #     env     => $message->env,
    #     type    => $message->type
    # );
}

__PACKAGE__->meta->make_immutable;
1;
