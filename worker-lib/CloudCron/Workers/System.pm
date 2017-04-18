package CloudCron::Workers::System;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use POSIX;

our $VERSION = '0.01';
#ABSTRACT: A simple distributed cloud friendly cron for the masses

with 'SQS::Worker', 'SQS::Worker::DecodeJson';

sub process_message {
    my ($self, $message) = @_;
    if ($self->_can_execute($message)) {
        my $env = $self->_prepare_env($message) || {};
        my $cmd = $self->_prepare_command($message);
        $self->execute($env, $cmd);
        $self->_log_command($message);
    }
}

sub _can_execute {
    my ($self, $message) = @_;
    if ($message->{ type } ne 'shell') {
        $self->log->error('Command not of type "shell". Will not be executed.');
    }
    return 1;
}

sub _prepare_env {
    my ($self, $message) = @_;
    return defined $message->{ env } ? $message->{ env } : {};
}

sub _prepare_command {
    my ($self, $message) = @_;
    return $message->{ command };
}

sub _log_command {
    my ($self, $message) = @_;
    map { $self->log->debug($_) } (
        "Executed command",
        "  type: $message->{ type }",
        "  cmd: $message->{ command }",
        #"  envs: " . Dumper($message->{ env })
        );
}

sub execute {
    my ($self, $env_ref, $cmd) = @_;
    my %env = %$env_ref;
    foreach my $var (keys %env) {
        #$self->log->debug("setting $var -> $env{ $var }");
        $ENV{$var} = $env{$var};
    }
    eval {
        $self->log->debug("about to execute $cmd");
        $0 = "cloudcron-worker for $cmd";
        if (system($cmd) != 0) {
            my $status = $?;
            if (WIFEXITED($status)){
              my $exitcode = WEXITSTATUS($status);
              $self->log->error("Exit status: $exitcode for $cmd");
            } elsif (WIFSIGNALED($status)) {
              my $sig = WTERMSIG($status);
              $self->log->error("Exited by signal: $sig on $cmd");
            } else {
              $self->log->error("Uncontrolled exit: $status for $cmd");
            }
        } else {
            $self->log->info("Command $cmd executed successfully");
        }
    };
    if ($@) {
        $self->log->error('Unknown error occurred: ' . $@);
    }
}

__PACKAGE__->meta->make_immutable;
1;
