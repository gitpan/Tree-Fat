# -*-perl-*- please

use Test;
BEGIN { todo tests => 1 }

use strict;
use Tree::Fat;
use IO::Handle;
use Time::HiRes qw(gettimeofday tv_interval);

my $pkg = 'Tree::Fat';
my $t = $pkg->new;

#srand(0);

my @set = ('A'..'Z','a'..'z');

#print "sizeof(TN)=".join(', ',$t->sizeof())."\n";

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
    my ($t,$elapse) = @_;
    my %s = $t->treestats();
    $s{fill} = $s{'fill'} / $s{'max'};
    delete $s{'max'};
    $s{'elapse'} = $elapse;
    for my $k (sort keys %s) {
	STDERR->printf("  %-12s %15.4f\n", $k, $s{$k});
    }
}

sub bench_array {
    for my $m (qw/ unshift push /) {
	for my $trial (2..3) {
	    $t->CLEAR;
	    my $sz = 3000 * $trial;
	    my $t0 = [gettimeofday];
	    for (my $x=0; $x < $sz; $x++) {
		$t->$m($x);
	    }
	    my $elapse = tv_interval ($t0, [gettimeofday]);
	    STDERR->print("$m $sz:\n");
#	    while ($t->compress(0)) {}
#	    while ($t->balance(0)) {}
#	    $t->balance(0);
	    treestats($t, $elapse);
	    $t0 = [gettimeofday];
	    for (my $x=0; $x < $sz; $x++) {
		$t->DELETE($x);
	    }
	    STDERR->printf("  %-12s %15.4f\n", 'delete', 
			   tv_interval ($t0, [gettimeofday]));
	}
    }
}

sub bench_random {
    for my $trial (2..4) {
	my $sz = 20000 * $trial;
	my $kset = keyset($sz);

	my $t0 = [gettimeofday];
	my $zc=0;
	for my $k (@$kset) {
	    $t->STORE($k,0);
	    if ($zc > 1000) {
		$t->compress(4);
		$zc=0;
	    }
	}
#	while ($t->compress(0)) {}
#	while ($t->balance(0)) {}
	my $elapse = tv_interval ($t0, [gettimeofday]);
#	$t->dump;
	STDERR->print("random $sz:\n");
	treestats($t, $elapse);
	$t0 = [gettimeofday];
	for my $k (@$kset) {
	    $t->DELETE($k);
	}
	STDERR->printf("  %-12s %15.4f\n", 'delete', 
		       tv_interval ($t0, [gettimeofday]));
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
ok(1);

__END__;


random 60000:
  center                0.2562
  depth                11.8560
  elapse                4.3365
  fill                  0.7557
  delete                3.4784
random 80000:
  center                0.4166
  depth                12.5816
  elapse                5.6059
  fill                  0.7577
  delete                4.5906
Cursor Stats:
  copyslot     1264865
  delete        139204
  depthcalc     542634
  insert        156734
  keycmp       7881119
  rotate1        23485
  rotate2         1222
  stepnode      161925
  tn_recalc      84290
