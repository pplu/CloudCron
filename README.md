CloudCron
=========

A simple distributed, cost effective, backwards-compatible, cloud friendly cron for the masses

Introduction
============

If you google around looking for a "cloud friendly cron" that runs on AWS: you're out of luck. You're 
probablly just trying to solve one thing: I have a crontab that I want to run on AWS

Solutions you find around tend to be in the following areas:

 - You need to build and maintain a complex, distributed, minimum of three nodes cluster

 - Make it a Lambda function (since Lambdas can be scheduled)

 - Put the crons code in your app server and call it via HTTP

Lots of times, users just put their cron on one "cron instance"


The CloudCron solution
======================

- Backwards-compatible

Give it a cron file, and it will run the same command you already have, on the same server if you want. No need for reprogramming your jobs

- Cost-Effective

With minimal infrastructure (just a worker node)

- Scalable/Parallelizable

Have more crons than a machine can handle? You can scale your worker nodes at need

- Red/Black deployment friendly

You can deploy a new worker node with new code or patches without downtime

- No time limits for the cron execution

Lambda based solutions have a maximum running time of 5 minutes

How does it work?
=================

CloudCron is basically split into two halves: a "cron compiler", that transforms a cronfile into CloudWatch events

Your crontab file gets transformed into a bunch of CloudWatch Events that get pushed to CloudFormation so they can be managed as a whole

These CloudWatch events inject a message for each ocurrance of a cron event to an SQS queue, which is getting polled by a worker process. This

worker process runs in the same machine (or machines) where your old cron could execute it's jobs.

Get me started
==============
```
cloudcron init --name MyCronQueue --region eu-west-1
```
This command deploys the SQS queue and informs you how to start a worker. We can have as many queues as we want (for, say, different groups of crons)
```
You can start a worker with:
cloudcron-worker --queue_url https://sqs.eu-west-1.amazonaws.com/012345678901/MyCronQueue-CloudCronQueue-LPNF3N07WF68 --region eu-west-1 --log_conf path_to_log_conf
```

First create a log configuration file:
```
printf "log4perl.appender.Screen = Log::Log4perl::Appender::Screen\nlog4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout\nlog4perl.appender.Screen.layout.ConversionPattern = [%%d][CloudCron] %%p %%m%%n\n# Catch all errors\nlog4perl.logger = INFO, Screen\n" > log.conf
```

And now launch the worker pointing to the log config you just created
```
cloudcron-worker --queue_url https://sqs.eu-west-1.amazonaws.com/012345678901/MyCronQueue-CloudCronQueue-LPNF3N07WF68 --region eu-west-1 --log_conf log.conf
```
The worker is now idle, waiting for it's first jobs, so we need to create them:

```
cloudcron deploy --name MyCronFile --destination_queue MyCronQueue --region eu-west-1 path_to_crontab_file
```
The name of the destination queue is the name we gave to cloudcron init

Once the deploy command finishes, we wait for the worker to start receiving the messages, and executing your jobs!

If you modify your crontab file, just redeploy. cloudcron will detect that you already deployed this cron, and will update the events:
```
cloudcron deploy --name MyCronFile --destination_queue MyCronQueue --region eu-west-1 path_to_crontab_file
```

Once you're ready, you can delete queues, and crons with the `cloudcron remove` command

Installation
============
TODO

Nitty gritty details
====================
 - Each event launched by CloudWatch events is delivered to the crons' queue. The worker picks up the message ***only once***, even if the job
   fails to execute (like in cron) it is not redelivered to the queue for retry. It's supposed that it will be executed a next time

 - Each cron queue has a dead letter queue. Here you could find messages due to severe malfunction: messages that were delivered to a worker, but
   never got acknowledged (deleted) in time (notice that workers immediately delete a message after recieving it, even before attempting to execute
   the job, so not deleting a message should not happen).

 - The system depends on SQS, so it's possible for an event to be processed more than one time by two concurrent workers

 - There is no reentrance contol (like cron, you should take care of that in your job) (or you can contribute a patch to avoid reentrance)

 - It's recommended to centralize the cloudcron logs with something like CloudWatch Logs
