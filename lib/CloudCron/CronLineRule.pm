package CloudCron::CronLineRule;
use Moose;

has line => (is => 'ro', isa => 'Int', required => 1);
has rule => (is => 'ro', isa => 'Cfn::Resource::AWS::Events::Rule');

__PACKAGE__->meta->make_immutable;
1;
