use CCfn;

package CloudCronSQSQueueArgs {
  use Moose;
  use CCfnX::Attachments;
  extends 'CCfnX::CommonArgs';

  has visibilityTimeout   => (
    is => 'ro', 
    isa => 'Int', 
    traits => ['StackParameter'], 
    default  => 30, 
    documentation => 'after receiving a msg in the queue, timeout until it will be visibile again'
  );
  has maxReceiveCount     => (
    is => 'ro', 
    isa => 'Int', 
    traits => ['StackParameter'], 
    required => 1,  
    documentation => 'Num of receives before redriving the msg to the dead letter queue'
  );
}



package CloudCronSQSQueue {
  use Moose;
  use CCfnX::Shortcuts;
  extends 'CCfn';

  has params => (
    is  => 'ro',
    isa => 'CloudCronSQSQueueArgs',
    default => sub { CloudCronSQSQueueArgs->new_with_options()  },
  );

  resource CloudCronDeadLetterQueue => 'AWS::SQS::Queue', {
    MessageRetentionPeriod => 1209600,  # 14 days (it's the maximum value)          
  };

  resource CloudCronQueue => 'AWS::SQS::Queue', {
    VisibilityTimeout => Ref('visibilityTimeout'),
    RedrivePolicy     => {
      deadLetterTargetArn => GetAtt('CloudCronDeadLetterQueue','Arn'),
      maxReceiveCount     => Ref('maxReceiveCount'),
    },        
  };
     
  output 'cloudcronqueue/sqsarn'           => GetAtt('CloudCronQueue', 'Arn');
  output 'cloudcronqueue/sqs'              => Ref('CloudCronQueue');
  output 'cloudcrondeadletterqueue/sqsarn' => GetAtt('CloudCronDeadLetterQueue', 'Arn');
  output 'cloudcrondeadletterqueue/sqs'    => Ref('CloudCronDeadLetterQueue');
}

