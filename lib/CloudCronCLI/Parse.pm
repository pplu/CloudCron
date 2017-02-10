package CloudCronCLI::Parse;
use MooseX::App::Command;

command_short_description q(This is the short description for Parse);
command_long_description q(This is the long description for parse);
command_usage q(cloudcron parse --file FILENAME);

option file => (
  is => 'rw',
  isa => 'Str',
  required => 1,
  documentation => q(The crontab file that you want to parse),
  cmd_aliases => [qw(f)],
);

sub run {
  my ($self) = @_;

  print "This is the Parse command YAY! \n";
}

1;

