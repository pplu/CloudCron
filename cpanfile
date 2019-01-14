requires 'Parse::Crontab';
requires 'ParseCron';
requires 'CloudDeploy';
requires 'Moose';
requires 'JSON';
requires 'MooseX::Getopt';
requires 'SQS::Worker', '0.05';
requires 'MooseX::App';
requires 'Log::Log4perl';
requires 'Path::Class';
requires 'Paws';
requires 'namespace::autoclean';

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
