# -*-perl-*- please

BEGIN { print "1..1\n"; }

use lib './t';
use test;
use strict;
use IO::Handle;
use Time::HiRes qw(gettimeofday tv_interval);

my $pkg = 'Tree::Fat';
my $t = $pkg->new;

#srand(0);

my @set = ('A'..'Z','a'..'z');

print "sizeof(TN)=".join(', ',$t->sizeof())."\n";

sub newkey {
    my $key = '';
    for (my $x=0; rand() < (1-$x/11); $x++) {
	$key .= $set[int(rand(@set))];
    }
    $key;
}

sub keyset {
    my ($c) = @_;
    my @k;
    for (my $x=0; $x < $c; $x++) {
	if (rand() < .9) {
	    push(@k, &newkey);
	} else {
	    push(@k, $k[ int(rand(@k)) ]);
	}
    }
    \@k;
}

sub treestats {
    my $t = shift;
    my %s = $t->stats();
    $s{fill} = $s{'fill'} / $s{'max'};
    delete $s{'max'};
    for my $k (sort keys %s) {
	printf("  %-12s %15.4f\n", $k, $s{$k});
    }
}

sub bench_array {
    my %elapse;
    for my $m (qw/ unshift push /) {
	for my $trial (1..2) {
	    $t->CLEAR;
	    my $sz = 3000 * $trial;
	    my $t0 = [gettimeofday];
	    for (my $x=0; $x < $sz; $x++) {
		$t->$m($x);
	    }
	    $elapse{$m} = tv_interval ($t0, [gettimeofday]);
	    print "$m $sz:\n";
	    treestats($t);
	}
    }
}

sub bench_random {
    my $elapse=0;
    for my $trial (1..3) {
	my $sz = 20000 * $trial;
	my $kset = keyset($sz);

	my $t0 = [gettimeofday];
	for my $k (@$kset) {
	    $t->STORE($k,undef);
	}
	$elapse += tv_interval ($t0, [gettimeofday]);
#	$t->dump;
	print "random $sz:\n";
	treestats($t);
	$t->CLEAR;
    }
}

&bench_array;
&bench_random;

{
    STDERR->print("Cursor Stats:\n");
    my %stats = $pkg->opstats();
    for my $k (sort keys %stats) {
	STDERR->printf("  %-12s %7d\n", $k, $stats{$k});
    }
}

__END__;

