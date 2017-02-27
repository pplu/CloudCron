# Quite a dumb class, but get_from_mongo was needed just because
# CloudFormationDeployer is calling it (it shouldn't be, as it's a 
# violation of concerns. This will get fixed in next CloudDeploy, 
# but for now this class is needed
package CCfnX::PersistentInCloudFormation {
  use Moose::Role;

  requires 'params';

  # Left these befores and afters commented just in
  # case we want to intervene in the deployment process
  #before undeploy => sub {
  #  my $self = shift;
  #};

  #after undeploy => sub {
  #  my $self = shift;
  #};

  #before deploy => sub {
  #  my $self = shift;
  #};

  #after deploy => sub {
  #  my $self = shift;
  #};

  #before redeploy => sub {
  #  my $self = shift;
  #};

  #after redeploy => sub {
  #  my $self = shift;
  #};

  sub get_from_mongo { }
}

1;
