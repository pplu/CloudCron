package CloudCron::AWS::CloudWatch::CustomParams {
  use Moose;
  extends 'CCfnX::CommonArgs';
};

package CloudCron::AWS::CloudWatch {
  use Moose;
  extends 'CCfn';
  use CCfnX::Shortcuts;

  has 'params' => (
    is => 'ro',
    isa => 'CloudCron::AWS::CloudWatch::CustomParams',
    required => 1,
  );

  output CloudCronVersion => '1';
}

1;
