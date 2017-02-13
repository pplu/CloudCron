package CloudCronCLI::DeleteQueue;
use MooseX::App::Command;

command_short_description q(Delete a queue in AWS with the given name); 
command_long_description q(Delete a queue in AWS with the given name); 
command_usage q(cloudcron delete_queue);

option name => (
  is => 'ro',
  isa => 'Str',
  required => 1,
  documentation => 'Queue name to be deleted.',
);

sub run {
  my ($self) = @_;

  chdir ('./lib');

  my @args = (
    'clouddeploy',
    'undeploy',
    $self->name,
  );

  eval {
    system(@args);
  };

  warn $@ if $@;

};


1;
