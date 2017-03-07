package CloudCronCLI::Deploy;
  use MooseX::App::Command;

  use Paws;
  use Cfn;
  use CloudCron::Compiler;
  use CloudCron::TargetQueue;
  use CloudCron::AWS::CloudWatch;
  use JSON;

  command_short_description q(Deploy a crontab file into AWS);
  command_long_description q(Parses a crontab file and deploys it into AWS);

  parameter crontab_file => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    documentation => 'The crontab file that you want to parse',
  );

  option name => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    documentation => 'The name for this cron deployment'
  );

  option destination_queue => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    documentation => 'The name of the initial deployment (the queue to attach to)'
  );

  option region => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    documentation => 'AWS region'
  );

  has cfn => (
    is => 'ro',
    lazy => 1,
    isa => 'Paws::CloudFormation',
    default => sub {
      my $self = shift;
      Paws->service('CloudFormation', region => $self->region)
    }
  );

  sub run {
    my ($self) = @_;

    my $stack = $self->get_stack_from_cfn_by_name($self->destination_queue);
    my $cron = $self->get_stack_from_cfn_by_name($self->name);

    if (not defined $stack) {
      die "Can't find a deployment with name '" . $self->destination_queue . "' in AWS" 
    }
    my $outputs = cfn_outputs_to_hash($stack->Outputs);


    my $params = CloudCron::AWS::CloudWatch::CustomParams->new(
      name => $self->name,
      region => $self->region,
      account => '',
      (defined $cron) ? (update => 1) : (),
    );
    my $cfn = CloudCron::AWS::CloudWatch->new(params => $params);

    my $deployer = $cfn->get_deployer({
    }, 'CCfnX::CloudFormationDeployer', 'CCfnX::PersistentInCloudFormation');

    my $target = CloudCron::TargetQueue->new({
      Arn => $outputs->{ queuearn },
      Id  => $self->name,
    });

    my $compiler = CloudCron::Compiler->new({
      file   => $self->crontab_file,
      target => $target
    });

    for my $rule ($compiler->rules) {
      my $name = 'CrontabLine' . $rule->line;
      $cfn->addResource($name, $rule->rule);
    }
    
    if (not defined $cron) {
      $deployer->deploy;
    } else {
      my $cron_outputs = cfn_outputs_to_hash($cron->Outputs);
      die "Not a Cron deployment" if ($cron_outputs->{ CloudCronVersion } ne '1');

      $deployer->redeploy;
    }
  }

  sub get_stack_from_cfn_by_name {
    my ($self, $name) = @_;
    my $stacks = eval {
      $self->cfn->DescribeStacks(
        StackName => $name
      );
    };
    if ($@) {
      if ($@->message =~ m/does not exist/) {
        return undef;
      } else {
        die $@;
      }
    }
    return $stacks->Stacks->[0];
  }

  sub cfn_outputs_to_hash {
    my $outputs = shift;
    my $hash = {};

    foreach my $output (@$outputs) {
      $hash->{ $output->OutputKey } = $output->OutputValue;
    }

    return $hash;
  }

1;

