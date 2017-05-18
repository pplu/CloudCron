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

- CD Pipeline friendly

You get the opportunity to version control your crontab, and deploy it as a part of your CD

How does it work?
=================

CloudCron is basically split into two halves: a "cron compiler", that transforms a cronfile into CloudWatch events

Your crontab file gets transformed into a bunch of CloudWatch Events that get pushed to CloudFormation so they can be managed as a whole

These CloudWatch events inject a message for each ocurrance of a cron event to an SQS queue, which is getting polled by a worker process. This

worker process runs in the same machine (or machines) where your old cron could execute it's jobs.

Installation
============

You can install CloudCron with any perl package manager. We recommend to use carton so you don't 
install dependencies in your system (carton is usually installable via your SOs package manager):

```
mkdir mycron
cd mycron
echo 'requires "CloudCron";' >> cpanfile
echo 'requires "CloudCron::Worker";' >> cpanfile
carton install
carton exec $SHELL -l
```

CloudCron is split in two parts:
 - the management interface package: CloudCron that enables you to create the necessary infrastructure
 - the worker package: CloudCron::Worker the process that runs on your cloud nodes

Get me started
==============
```
cloudcron init --name MyCronQueue --region eu-west-1
```
This command deploys the SQS queue and informs you how to start a worker. We can have as many queues as we want (for different groups of crons, for example)

You can start a worker the output of the last command, but first create a log configuration file:
```
printf "log4perl.appender.Screen = Log::Log4perl::Appender::Screen\nlog4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout\nlog4perl.appender.Screen.layout.ConversionPattern = [%%d][CloudCron] %%p %%m%%n\n# Catch all errors\nlog4perl.logger = INFO, Screen\n" > log.conf
```

And now launch the worker in background, pointing to the log config you just created
```
cloudcron-worker --queue_url https://sqs.eu-west-1.amazonaws.com/012345678901/MyCronQueue-CloudCronQueue-LPNF3N07WF68 --region eu-west-1 --log_conf log.conf &
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

Nitty gritty details
====================
 - Each event launched by CloudWatch events is delivered to the crons' queue. The worker picks up the message ***only once***, even if the job
   fails to execute (like in cron) it is not redelivered to the queue for retry. It's supposed that it will be executed a next time

 - Each cron queue has a dead letter queue. Here you could find messages due to severe malfunction: messages that were delivered to a worker, but
   never got acknowledged (deleted) in time (notice that workers immediately delete a message after recieving it, even before attempting to execute
   the job, so not deleting a message should not happen).

 - The worker executes with limited privileges. You control the user which the worker runs with. The worker shouldn't be run as root (unless you have good reasons to)

Known Limitations
=================
 - The system depends on SQS, so it's possible for
   - events to be processed out of order
   - events to be processed more than one time by two concurrent workers. 

   SQS recently got FIFO and exactly once delivery. It's on the TODO list to take advantage of that capability to provide a more cron-like behaviour

 - There is no reentrance contol (like cron, you should take care of that in your job) (or you can contribute a patch to avoid reentrance)

 - It's recommended to centralize the cloudcron logs with something like CloudWatch Logs if you're executing on autoscaling groups, for example.

 - If you don't have workers polling a queue, events still get delivered to it and accumulate, so it's possible that you accumulate invocations of lots of events if you don't have a worker running.

   SQS recently got a deduplication facility which we can use to try to avoid message accumulation

 - If the system that hosts the worker fails before an event has fully executed, the event will not be retried

TOPOLOGIES
==========

With cloudcron you can generate a lot of differente topologies to suit your needs:

Single crontab
--------------

```
crontab ---> Queue <--- Worker node
```

 - create a queue with cloudcron init
 - deploy your crontab file with cloudcron deploy
 - start a cloudcron-worker on the machine that has to do the work

Lots of jobs (multinode)
------------------------

If one machine is not enough to handle the load of all your crons, you can just 
add more cloudcron-workers polling the same queue

```
                                      |---- Worker node 1
crontab (lots of jobs)  ---> Queue <--|---- Worker node 2
                                      |---- Worker node 3
```

 - create a queue with cloudcron init
 - deploy your crontab file with cloudcron deploy
 - start one cloudcron-worker for each machine that has to do the work

Lots of jobs (autoscaling)
--------------------------

If the load on your worker nodes varies enough, you might want to autoscale your
worker node fleet applying autoscaling to the worker node pool autoscaling group

```
                                     |-A--   
crontab (lots of jobs) ---> Queue <--|-S-- Worker node N
                      |              |-G--
                      |                |
                      +--- CloudWatch--+
```

Caution should be taken: when autoscaling shuts down a worker instance, it will kill the
processes actually executing. There is no facility in cloudcron to let your jobs finish
(contributions welcome :))

Manage lots of jobs
-------------------

You can deploy independant crontab files to the same queue, as long as the worker polling
the queue is able to execute the commands in your crontab.

```
crontab for ETLs -----+
                      |
crontab for cleanup --+---> Queue <--- Worker node
                      |
crontab for X --------+
```

 - create a queue with cloudcron init
 - deploy each crontab file with cloudcron deploy to the same queue
 - start a cloudcron-worker on the machine that has to do the work

Crons running with different users
----------------------------------

You can deploy an independant worker for each user. The two workers can
run on the same instance

```
crontab for user1 ----> Queue1 <---- Worker running with user1

crontab for user2 ----> Queue2 <---- Worker running with user2
```

 - create two queues with cloudcron init
 - deploy each crontab to it's queue with cloudcron deploy
 - start a worker under user1 pointing to the queue that it's cron points to
 - start the other worker under user2 pointing to the queue that it's cron points to 

Flexibility (custom topologies)
-------------------------------

You can combine these scearios as you want to adapt them to your needs. 
Mix, match, and report your topologies back so we can document them!

Deploying cloudcron-worker
==========================

In the examples directory there is a sample of how to run a cloudcron-worker from an 
upstart job


