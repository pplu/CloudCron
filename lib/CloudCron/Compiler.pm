package CloudCron::Compiler;
use Moose;
use namespace::autoclean;

use CloudCron::Parser;
use CloudCron::TargetInput;
use CloudCron::CronLineRule;
use Cfn;
use Cfn::Resource::AWS::Events::Rule;
use Cfn::Resource::Properties::AWS::Events::Rule;
use Path::Class;
use Carp;
use ParseCron;

has target  => (is => 'ro', isa => 'CloudCron::TargetQueue', required => 1);
has content => (is => 'ro', isa => 'Str', lazy => 1, default => sub {
    my $self = shift;
    croak 'Attribute file or content is required!' unless defined $self->file;
    Path::Class::file($self->file)->slurp;
});
has parser  => (is => 'ro', isa => 'CloudCron::Parser', lazy => 1, builder => '_parser');
has file    => (is => 'ro');
has translator => (is => 'ro', isa => 'ParseCron', lazy => 1, builder => '_translator');

sub _translator {
    my $self;
    return ParseCron->new;
}

sub _parser {
    my $self = shift;
    return CloudCron::Parser->new({ content => $self->content });
}

sub rules {
    my $self = shift;

    die "Invalid crontab specification" if !$self->parser->is_valid;
    my @jobs = $self->parser->jobs;
    return map { $self->_as_line_rule($_); } @jobs;
}

sub _as_line_rule {
    my ($self, $job) = @_;
    return CloudCron::CronLineRule->new({
        line => $job->line_number,
        rule => $self->_as_rule($job),
    });
}

sub envs {
    my $self = shift;
    return $self->parser->envs;
}

sub _as_rule {
    my ($self, $job) = @_;
    return Cfn::Resource::AWS::Events::Rule->new({
        Properties => $self->_get_properties($job),
    });
}

sub _cron {
    my $self = shift;
    my $job = shift;
    return join ' ', map { $job->$_->entity } qw/minute hour day month day_of_week/;
}

sub _name {
    my ($self, $job) = @_;
    my @parts = split /\//, $job->command;
    return $parts[$#parts];
}

sub _input {
    my ($self, $job, @envars) = @_;
    my @aux = map { ($_->key, $_->value) } @envars;
    my %envs_hash = @aux;
    return CloudCron::TargetInput->new({
        command => $job->command,
        env => \%envs_hash,
    });
}

sub _description { # name.  human cron schedule
    my ($self, $job) = @_;
    my $name = $self->_name($job);
    my $human = $self->translator->parse_cron(join ' ', map { $job->$_->entity } qw/minute hour day month day_of_week/);
    return $name . " " . $human;
}

sub _get_properties {
    my $self = shift;
    my $job = shift;
    my $cron = $self->_cron($job);
    my $name = $self->_name($job);
    my $description = $self->_description($job);
    my $input = $self->_input($job, $self->envs);
    return Cfn::Resource::Properties::AWS::Events::Rule->new({
        Description => $description,
        ScheduleExpression => "cron($cron)",
        State => 'ENABLED',
        Targets => [
            {
                Arn   => $self->target->Arn,
                Id    => $self->target->Id,
                Input => $input->json,
            },
        ],
    });
}

__PACKAGE__->meta->make_immutable;
1;
