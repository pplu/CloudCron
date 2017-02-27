package CloudCronCLI::Init;
  use MooseX::App::Command;
  use CloudDeploy::Utils;

  command_short_description q(Initialize AWS account for executing CloudCron); 
  command_long_description q(Deploys the necessary infrastructure to execute crons in AWS); 

  option name => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    documentation => 'Name of the CloudCron',
  );

  option region => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    documentation => 'AWS region to deploy to'
  );

  sub run {
    my $self = shift;

    my $module = load_class('CloudCron::AWS::Queue');
    my $cc = $module->{class}->new(
      params => $module->{params_class}->new(
        region => $self->region,
        name => $self->name,
        account => '',
      )
    );

    my $deployment = $cc->get_deployer({
    },'CCfnX::CloudFormationDeployer', 'CCfnX::PersistentInCloudFormation');

    eval {
      $deployment->deploy;
    };
    if ($@) {
      print $@->message, "\n";
    }

    my $stack = get_stack_from_cfn_by_name($deployment->cfn, $self->name);
    if (defined $stack) {
      my $outputs = cfn_outputs_to_hash($stack->Outputs);

      printf "You can start a worker with:\n";
      printf "cloudcron-worker --queue_url %s --region %s --log_conf path_to_log_conf\n", 
             $outputs->{ queueurl }, 
             $self->region;
    }
  }

  sub get_stack_from_cfn_by_name {
    my ($cfn, $name) = @_;
    my $stacks = eval {
      $cfn->DescribeStacks(
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
