use Test::Spec;
use strict;
use CloudCron::Workers::System;
use CloudCron::TargetInput;
use CloudCron::Compiler;
use Data::Dumper;
use JSON;
#use Mocks;

my $DO_LOG = 1;
sub mk_log {
    my $level = shift;
    return sub {
        my ($self, $msg) = @_;
        if ($DO_LOG) {
            print STDERR "[" . $level . "] " . $msg . "\n";
        }
    };
}

sub mk_noop { return sub {}; }

describe "CloudCron::Workers::System" => sub {

    # this is of the form the cloudcron compiler generates for the Input fileld of an Event::Rule
    # that is what is to be passed to the SQSs
    my $msg = "{\"env\":{\"HOME\":\"/opt/deploy/code/portal/\",\"BASH_ENV\":\"/etc/default/portal\",\"PERL5LIB\":\"/opt/deploy/code/portal/local/lib/perl5/\",\"PATH\":\"/opt/capside/perl-5.16.3/bin/:usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games\"},\"type\":\"shell\",\"command\":\"bash -c /opt/deploy/code/portal/script/timeworked_reports\"}";

    $msg = encode_json({
        env => { PAU => 'pau' },
        type => "shell",
        command => 'ls -lah',
    });

    my $log_stub = stub(
        error => mk_log('error'),
        warn  => mk_log('wanr'),
        info  => mk_noop, #mk_log('info'),
        debug => mk_log('debug'),
    );

    my $msg_stub = stub(
        ReceiptHandle => 'abcdef',
        Body => $msg);

    my $sqs_mock = stub(
        ReceiveMessage => sub {
            return stub(
                Messages => [$msg_stub]
                #     stub(
                #         ReceiptHandle => 'abcdefg',
                #         Body => $msg,
                #     )
                # ]
            );
        },
        DeleteMessage => sub { },
        isa => sub { 'Paws::SQS' },
    );
    #my $log_stub = mock_log();
    #my $sqs_mock = mock_sqs();

    my $worker;
    before each => sub {
        $worker = CloudCron::Workers::System->new({
            queue_url => '',
            region => '',
            sqs => $sqs_mock,
            log => $log_stub,
        });
        #
    };

    it "can fetch message" => sub {
        my $expectation = $worker->expects('process_message')->once;
        $worker->fetch_message;
        ok($expectation->verify);
    };

    it "can fetch 2 messages" => sub {
        my $expectation = $worker->expects('process_message')->exactly(2)->times;
        $worker->fetch_message;
        $worker->fetch_message;
        ok($expectation->verify);
    };

    it "receives a correct message" => sub {
        my $expectation = $worker
            ->expects('process_message')
            ->with_eq($msg_stub);
        $worker->fetch_message;
        ok($expectation->verify);
    };

    it "receives the correct environment" => sub {
        my $expectation = $worker
            ->expects('execute')->once;
            #->with_eq('command message');
        $worker->fetch_message;
        ok($expectation->verify);
    };

    it "executes without failing" => sub {
        $worker->fetch_message;
    };

};

runtests unless caller;
1;
