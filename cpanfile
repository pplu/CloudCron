requires 'Parse::Crontab';
requires 'ParseCron';
requires 'CloudDeploy';
requires 'Moose';
requires 'JSON';
requires 'MooseX::Getopt';
requires 'SQS::Worker';
requires 'MooseX::App';
requires 'Log::Log4perl';

on 'develop' => sub {
  requires 'Test::Spec';
  requires 'Test::Perl::Critic';
  requires 'Data::Dumper';
  requires 'Test::Output';
  requires 'Dist::Zilla';
  requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
  requires 'Dist::Zilla::Plugin::VersionFromModule';
  requires 'Dist::Zilla::PluginBundle::Git';
};
