use CCfn;

package CloudCronSQSQueueArgs {
  use Moose;
  use CCfnX::Attachments;
  extends 'CCfnX::CommonArgs';

};

package CloudCron::AWS::Queue {
  use Moose;
  use CCfnX::Shortcuts;
  extends 'CCfn';

  has params => (
    is  => 'ro',
    isa => 'CloudCronSQSQueueArgs',
    default => sub { CloudCronSQSQueueArgs->new_with_options()  },
  );

  stack_version 1;

  # DLQ
  # 14 days of retention in the DLQ (it's the maximum value)
  resource CloudCronDeadLetterQueue => 'AWS::SQS::Queue', {
    MessageRetentionPeriod => 1209600,  
  };

  # CronQueue
  #
  # maxReceiveCount is set to 1 so that we don't process the same message
  # more than one time. If something unexpected happens: the message will
  # go to the DLQ
  #
  # The visibility timeout of messages is 1h. The messages are deleted 
  # immediately by the worker upon reception (before the task is executed, so 
  # almost inmediately), so redeliver of a message due to a visibilityTimeout 
  # event should be some fault in the worker process (can't delete messages, f.ex)
  #
  # visibility timeout combined with the fact that messages are never redelivered 
  # to the CronQueue (due to maxReceiveCount) should mean that messages in the DLQ
  # are due to severe malfunction in the system
  resource CloudCronQueue => 'AWS::SQS::Queue', {
    VisibilityTimeout => 60 * 60,
    RedrivePolicy     => {
      deadLetterTargetArn => GetAtt('CloudCronDeadLetterQueue','Arn'),
      maxReceiveCount     => 1,
    },
  };

  resource CWEToSQSPolicy => 'AWS::SQS::QueuePolicy', {
      PolicyDocument => {
          Id => "AllowCloudWatchEventsPolicy",
          Statement => [{
              Sid => "1",
              Effect => "Allow",
              Principal => {
                  AWS => "*",
              },
              Action => "sqs:SendMessage",
              Resource => GetAtt('CloudCronQueue', 'Arn'),
              Condition => {
                  ArnEquals => {
                      'AWS:SourceArn' => CfString('arn:aws:events:#-#AWS::Region#-#:#-#AWS::AccountId#-#:rule/*'),
                  }
              },
        }]
      },
      Queues => [Ref('CloudCronQueue')],
  };

  output 'name'     => Ref('AWS::StackName');
  output 'queuearn' => GetAtt('CloudCronQueue', 'Arn');
  output 'queueurl' => Ref('CloudCronQueue');
  output 'dlqarn'   => GetAtt('CloudCronDeadLetterQueue', 'Arn');
  output 'dlqurl'   => Ref('CloudCronDeadLetterQueue');
};

1;
