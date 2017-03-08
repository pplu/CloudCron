package CloudCronCLI::Remove;
  use MooseX::App::Command;

  use Paws;
  use JSON;
  use CloudDeploy::Utils;
  use CloudCron::AWS::CloudWatch;

  command_short_description q(Delete a crontab queue or a crontab from AWS);

  option cron_name => (
    is => 'ro',
    isa => 'Str',
    documentation => 'The name of the cloudcron deployment'
  );

  option queue_name => (
    is => 'ro',
    isa => 'Str',
    documentation => 'The name of the cloudcron queue deployment'
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

    die "Nothing to remove. Try specifying --queue_name or --cron_name parameters" if (not defined $self->queue_name and not defined $self->cron_name);

    if (defined $self->queue_name) {
      my $queue = $self->get_stack_from_cfn_by_name($self->queue_name) if (defined $self->queue_name);
      die "Can't find a stack named " . $self->queue_name if (not defined $queue);

      my $q_outputs = cfn_outputs_to_hash($queue->Outputs);
      die "The parameter in queue_name is not a cloudcron queue" if (not defined $q_outputs->{ CloudCronQueueVersion });
      die "The parameter in queue_name is not a known version of CloudCronQueue" if ($q_outputs->{ CloudCronQueueVersion } ne '1');
      my $module = load_class('CloudCron::AWS::Queue');
      my $cc = $module->{class}->new(
        params => $module->{params_class}->new(
          region => $self->region,
          name => $self->queue_name,
          account => '',
        )
      );

      my $deployment = $cc->get_deployer({
      },'CCfnX::CloudFormationDeployer', 'CCfnX::PersistentInCloudFormation');

      $deployment->undeploy;
    }

    if (defined $self->cron_name) {
      my $cron = $self->get_stack_from_cfn_by_name($self->cron_name);
      die "Can't find a stack named " . $self->cron_name if (not defined $cron);

      my $c_outputs = cfn_outputs_to_hash($cron->Outputs);
      die "The parameter in cron_name is not a cloudcron queue" if (not defined $c_outputs->{ CloudCronVersion });
      die "The parameter in cron_name is not a known version of a CloudCron" if ($c_outputs->{ CloudCronVersion } ne '1');

      my $params = CloudCron::AWS::CloudWatch::CustomParams->new(
        name => $self->cron_name,
        region => $self->region,
        account => '',
      );
      my $cfn = CloudCron::AWS::CloudWatch->new(params => $params);

      my $deployer = $cfn->get_deployer({
      }, 'CCfnX::CloudFormationDeployer', 'CCfnX::PersistentInCloudFormation');


      $deployer->undeploy;
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

