use Test::Spec;
use strict;

use CloudCron::TargetInput;

describe "TargetInput" => sub {

    my $ti = CloudCron::TargetInput->new({
        command => "my_command.pl",
        env => {
            HOME => '/my/home',
            PATH => '/my/path',
        }
    });

    it "has env" => sub {
        ok(grep { $_ eq 'HOME' } (keys $ti->env));
    };

    it "has env" => sub {
        my $json = $ti->json;
        ok($json =~ /env/);
    };

    it "has env vars" => sub {
        my $json = $ti->json;
        ok($json =~ /HOME/ && $json =~ /PATH/);
    };

    it "has command" => sub {
        my $json = $ti->json;
        ok($json =~ /command/);
    };

};

runtests unless caller;
1;
