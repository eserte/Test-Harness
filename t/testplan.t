#!/usr/bin/perl -w

BEGIN {
    unshift @INC, 't/lib';
}

use strict;
use warnings;
use TAP::Harness;
use Test::More;
use File::Path qw/mkpath rmtree/;
use File::Spec::Functions qw/catdir catfile rel2abs/;

if ( eval { require CPAN::Meta::YAML; 1 } ) {
    plan tests => 2;
}
else {
    plan skip_all => "requires CPAN::Meta::YAML";
}

# create temp directories long-hand
# XXX should we add File::Temp as a prereq to do this?
my $initial_dir = rel2abs(".");
my $work_dir = catdir($initial_dir, "tmp" . int(rand(2**31)));
my $t_dir = catdir($work_dir, 't');
mkpath($t_dir) or die "Could not create $t_dir: $!";
chdir $work_dir;

# clean up at the end, but only if we didn't skip
END { if ($initial_dir) {chdir $initial_dir; rmtree($work_dir) } }

# Create test plan in t
{
    open my $fh, ">", catfile($t_dir, "testplan.yml");
    print {$fh} <<'HERE';
---
par: t/p*.t
HERE
    close $fh;
}

my $th = TAP::Harness->new;
my $exp = {
    par => 't/p*.t'
};
is_deeply( $th->rules, $exp, "rules set from t/testplan.yml" );

# Create test plan in dist root
{
    open my $fh, ">", catfile($work_dir, "testplan.yml");
    print {$fh} <<'HERE';
---
seq:
- seq: t/p*.t
- par: '**'
HERE
    close $fh;
}

$th = TAP::Harness->new;
$exp = {
    seq => [
        { seq => 't/p*.t' },
        { par => '**' },
    ],
};
is_deeply( $th->rules, $exp, "root testplan.yml overrides t/testplan.yml" );
