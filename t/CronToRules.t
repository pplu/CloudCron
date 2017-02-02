use Test::Spec;
use strict;

use CloudCron::Compiler;

describe "Compiler" => sub {

    it "can compile a valid crontab spec" => sub {
        my $compiler = CloudCron::Compiler->new({
            content => '0 23 * * * bash -c datetime'
        });
        eval {
            my @rules = $compiler->rules;
        };
        warn $@ if $@;
        $@ ? ok(0) : ok(1);
    };

    it "can't compile an invalid crontab spec" => sub {
        my $compiler = CloudCron::Compiler->new({
            content => 'too much code will kill you'
        });
        eval {
            my @rules = $compiler->rules;
        };
        warn $@ if $@;
        $@ ? ok(1) : ok(0);
    };

    it "can compile multiple lines" => sub {
        my $compiler = CloudCron::Compiler->new({
            content =>
'0 23 * * * bash -c datetime
0 23 1 * * bash -c datetime',
        });
        eval {
            my @rules = $compiler->rules;
        };
        warn $@ if $@;
        $@ ? ok(0) : ok(1);
    };

    it "will give you a rule if there's only one rule" => sub {
        my $compiler = CloudCron::Compiler->new({
            content => '0 23 * * * bash -c datetime',
        });
        my @rules = $compiler->rules;
        is(scalar @rules, 1);
    };

    it "will give you a rule for each crontab line" => sub {
        my $compiler = CloudCron::Compiler->new({
            content =>
'0 23 * * * bash -c datetime
0 23 1 * * bash -c datetime',
        });
        my @rules = $compiler->rules;
        is(scalar @rules, 2);
    };

    it "will give you an instance of a Rule" => sub {
        my $compiler = CloudCron::Compiler->new({
            content => '0 23 * * * bash -c datetime',
                                                });
        my @rules = $compiler->rules;
        my $rule = $rules[0];
        ok($rule->isa('Cfn::Resource::AWS::Events::Rule'));
    };

    it "can parse environment variables also" => sub {
        my $compiler = CloudCron::Compiler->new({
            content =>
'PATH=/my/path
# comment line
0 23 * * * bash -c datetime',
});
        my @envs = $compiler->envs;
        my $env = $envs[0];
        ok($env->isa('Parse::Crontab::Entry::Env') &&
           $env->key eq 'PATH' && $env->value eq '/my/path');
    };

};

runtests unless caller;
1;
