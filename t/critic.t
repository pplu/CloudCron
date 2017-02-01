use strict;
use Cwd;
use Test::Perl::Critic;# (-severity => $ARGV[0]);

my $testdir = getcwd;
all_critic_ok(map { $testdir . "/" . $_ } qw( lib t bin ));
