package Mocks;
use Test::Spec;

my $log_stub = stub(
    error => sub { print STDERR "\nE: " . shift . "\n"; },
    warn  => sub {},
    info  => sub {},
    debug => sub {},
    );

sub mock_log {
    return $log_stub;
};

sub mock_sqs {

my $sqs_mock = stub(
    ReceiveMessage => sub {
        return stub(
            Messages => [
                stub(
                    ReceiptHandle => 'abcdefg',
                    Body => 'I am the message',
                )
            ]
            );
    },
    DeleteMessage => sub { },
    isa => sub { 'Paws::SQS' },
    );

return $sqs_mock;
};
