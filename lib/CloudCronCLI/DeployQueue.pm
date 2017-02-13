package CloudCronCLI::DeployQueue;
use MooseX::App::Command;

command_short_description q(This is the short description for deployqueue); 
command_long_description q(This is the long description for deployqueue); 
command_usage q(cloudcron deployqueue);

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
