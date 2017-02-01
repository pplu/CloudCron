requires 'Parse::Crontab';
requires 'ParseCron';
requires 'CloudDeploy';

on 'develop' => sub {
  requires 'Test::Spec';
};
