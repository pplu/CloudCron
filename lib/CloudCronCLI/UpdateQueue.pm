package CloudCronCLI::UpdateQueue;
use MooseX::App::Command;

command_short_description q(Update a queue in AWS with the given name); 
command_long_description q(Update a queue in AWS with the given name); 
command_usage q(cloudcron updatequeue);

option name => (
  is => 'ro',
  isa => 'Str',
  required => 1,
  documentation => 'Queue name to be updated.',
);

sub run {
  my ($self) = @_;

  chdir ('./lib');

  my @args = (
    'clouddeploy',
    'update',
    $self->name,
  );

  eval {
    system(@args);
  };

  warn $@ if $@;

};


1;
