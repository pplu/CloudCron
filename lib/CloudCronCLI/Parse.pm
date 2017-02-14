package CloudCronCLI::Parse;
use MooseX::App::Command;

use Cfn;
use CloudCron::Compiler;
use CloudCron::TargetQueue;
use CloudCron::AWS::CloudWatch;
use JSON;

command_short_description q(Parse a crontab file into CloudWatchEvents);
command_long_description q(Parse a crontab file into CloudWatchEvents);
command_usage q(cloudcron parse --file FILENAME --sqs_arn SQS_ARN --sqs_name SQS_NAME [--prefix prefix]);

option file => (
  is => 'ro',
  isa => 'Str',
  required => 1,
  documentation => 'The crontab file that you want to parse.',
  #cmd_aliases => ['f'],
    );

option name => (
    is => 'ro',
    isa => 'Str',
    required => 0,
    default => sub { 'CloudCronWatchEventsRules' },
    documentation => 'Name of the CWE');

option region => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    documentation => 'AWS region');

option sqs_arn => (
  is => 'ro',
  isa => 'Str',
  required => 1,
  documentation => 'The Amazon Resource Name (ARN) of the queue.',
);

option sqs_name => (
  is => 'ro',
  isa => 'Str',
  required => 0,
  lazy => 1,
  default => sub {
    my $self = shift;
    my $arn = $self->sqs_arn || '';
    $arn =~ s/\d//g;
    $arn =~ s/\-//g;
    return $arn;
  },
  documentation => 'The user-defined unique sqs_name of the target queue.',
);

option prefix => (
  is => 'ro',
  isa => 'Str',
  required => 0,
  default => sub { 'CrontabLine' },
  documentation => 'Prefix to the resource number.',
);

sub run {
  my ($self) = @_;

  my $target = CloudCron::TargetQueue->new({
    Arn => $self->sqs_arn,
    Id  => $self->sqs_name,
   });

  my $params = CloudCron::AWS::CloudWatch::CustomParams->new(
      name => $self->name,
      region => $self->region
      );
  my $cfn = CloudCron::AWS::CloudWatch->new(params => $params);
  my $compiler = CloudCron::Compiler->new({
    file   => $self->file,
    target => $target
  });

  for my $rule ($compiler->rules) {
    my $name = $self->prefix . $rule->line;
    $cfn->addResource($name, $rule->rule);
  }

  my $deployer = $cfn->get_deployer({
      access_key => $ENV{AWS_ACCESS_KEY_ID},
      secret_key => $ENV{AWS_SECRET_ACCESS_KEY},
      account => $ENV{CPSD_AWS_ACCOUNT},
  }, 'CCfnX::CloudFormationDeployer');
  $deployer->deploy;

  print encode_json($cfn->as_hashref);
}

1;

