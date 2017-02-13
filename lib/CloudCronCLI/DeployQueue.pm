package CloudCronCLI::DeployQueue;
use MooseX::App::Command;

command_short_description q(This is the short description for deployqueue); 
command_long_description q(This is the long description for deployqueue); 
command_usage q(cloudcron deployqueue);

sub run {
  my ($self) = @_;
}


1;
