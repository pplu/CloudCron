package CloudCronCLI::DeployQueue;
use MooseX::App::Command;

command_short_description q(Deploy a queue in AWS with specified name and region); 
command_long_description q(Deploy a queue in AWS with specified name and region); 
command_usage q(cloudcron deploy_queue);

option name => (
  is => 'ro',
  isa => 'Str',
  required => 1,
  documentation => 'Queue name to be deployed.',
);

option region => (
  is => 'ro',
  isa => 'Str',
  required => 1,
  documentation => 'Region from AWS to deploy Queue to.'
);

sub run {
  my ($self) = @_;

  chdir ('./lib');

  my @args = (
    'clouddeploy',
    'deploy',
    'CloudCron/AWS/Queue.pm',
    '--',
    '--name',
    $self->name,
    '--region',
    $self->region,
  );

  eval {
    system(@args);
  };

  warn $@ if $@;

};


1;
