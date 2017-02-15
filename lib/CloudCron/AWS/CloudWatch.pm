package CloudCron::AWS::CloudWatch::CustomParams {
    use Moose;
    extends 'CCfnX::CommonArgs';


    has name => (
        is => 'ro',
        isa => 'Str',
        required => 0,
        default => sub { 'CloudCronWatchEventsRules' },
        documentation => 'Name of the CWE');

    has region => (
        is => 'ro',
        isa => 'Str',
        required => 1,
        documentation => 'AWS region');
};

package CloudCron::AWS::CloudWatch {
    use Moose;
    extends 'CCfn';

    has params => (
        is => 'ro',
        isa => 'CloudCron::AWS::CloudWatch::CustomParams',
        required => 1,
    );

    sub get_deployer {
        my $self = shift;
        my $deployer = CCfnX::Deployment->new_with_roles(
            { origin => $self },
            'CCfnX::CloudFormationDeployer');#, 'CCvnX::PersistentDeployment');
        return $deployer;
    }
};

1;
