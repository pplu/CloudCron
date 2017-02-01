requires 'Parse::Crontab';
requires 'ParseCron';
requires 'CloudDeploy';
requires 'Moose';

on 'develop' => sub {
  requires 'Test::Spec';
};
