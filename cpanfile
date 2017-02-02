requires 'Parse::Crontab';
requires 'ParseCron';
requires 'CloudDeploy';
requires 'Moose';
requires 'JSON';

on 'develop' => sub {
  requires 'Test::Spec';
  requires 'Test::Perl::Critic';
  requires 'Data::Dumper';
};
