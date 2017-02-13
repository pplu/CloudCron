package CloudCronCLI::Parse;
use MooseX::App::Command;

use Cfn;
use CloudCron::Compiler;
use CloudCron::TargetQueue;
use JSON;

command_short_description q(Parse a crontab file into CloudWatchEvents);
command_long_description q(Parse a crontab file into CloudWatchEvents);
command_usage q(cloudcron parse --file FILENAME --arn ARN --id ID [--prefix prefix]);

option file => (
  is => 'ro',
  isa => 'Str',
  required => 1,
  documentation => 'The crontab file that you want to parse.',
  #cmd_aliases => ['f'],
);

option arn => (
  is => 'ro',
  isa => 'Str',
  required => 1,
  documentation => 'The Amazon Resource Name (ARN) of the queue.',
);

option id => (
  is => 'ro',
  isa => 'Str',
  required => 1,
  documentation => 'The user-defined unique id of the target queue.',
);

option prefix => (
  is => 'ro',
  isa => 'Str',
  required => 0,
  default => sub { 'crontab-line-' },
  documentation => 'Prefix to the resource number.',
);

sub run {
  my ($self) = @_;

  my $target = CloudCron::TargetQueue->new({
    Arn => $self->arn,
    Id  => $self->id,
   });

  my $cfn = Cfn->new;
  my $compiler = CloudCron::Compiler->new({
    file   => $self->file,
    target => $self->target
  });
  
  for my $rule ($compiler->rules) {
    my $name = $self->prefix . $rule->line;
    $cfn->addResource($name, $rule->rule);
  }

  my $hr => $cfn->as_hashref;

  print encode_json $hr;
}

1;

