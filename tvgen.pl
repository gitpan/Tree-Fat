#!/usr/local/bin/perl -w

use strict;
use Getopt::Std;
use IO::File;

sub usage {
    print "usage: tvgen.pl [-p prefix]\n";
}

my %opt;
getopts("p:",\%opt) or &usage;
@ARGV==0 or &usage;

$opt{p} ||= 'MYPREFIX_';
print "Using prefix '$opt{p}'...\n";

my $dname = 'Tree/Fat';
my $LIB;
for my $d (@INC) {
    if (-f "$d/$dname/tv.sym") {
	$LIB = "$d/$dname";
	last;
    }
}
die "tvgen.pl: cannot find tv template files in \@INC (".join(' ', @INC).")" 
    if !$LIB;

my %sym; {
    my $sym = new IO::File;
    $sym->open("$LIB/tv.sym") or die "open $LIB/tv.sym: $!";
    my @sym = <$sym>;
    chop(@sym);
    for my $s (@sym) {
	if ($s =~ m/^ struct \s+ (\w+) $/x) {
	    $sym{'struct \s+ '.$1} = "struct $opt{p}$1";
	} else {
	    $sym{$s} = "$opt{p}$s";
	}
    }
    $sym{'tv\.seek'} = "$opt{p}tvseek.ch";
}

my $conf_h = "./$opt{p}tv.tmpl";
my %fmap = (
	    "$LIB/tv.code"    => "$opt{p}tv.c",
	    "$LIB/tv.seek"    => "$opt{p}tvseek.ch",
	    "$LIB/tv.private" => "$opt{p}tvpriv.h",
	    "$LIB/tv.public"  => "$opt{p}tvpub.h",
	    $conf_h => "$opt{p}tv.h",
	   );
if (!-e $conf_h) {
    print "cp -i $LIB/tv.setup $conf_h\n";
    system("cp -i $LIB/tv.setup $conf_h")==0 or die "cp $LIB/tv.setup $conf_h: $!";
    chmod(0666, $conf_h);
}

my $fh = new IO::File;
my $to = new IO::File;
for my $f (sort keys %fmap) {
#    my $stem = $f;
#    $stem =~ s,^.*\/,,;
    $fh->open("$f") or die "open $f: $!";
    $to->open(">".$fmap{$f}) or die "open >$fmap{$f}: $!";
    $to->print("/* Doing namespace management in -*-C-*- is horrible. */\n");
    $to->print("/* Generated by tvgen.pl at ".localtime()."! */\n");
    $to->print("/* !! DO NOT MODIFY THIS FILE !! */\n");
    if ($f =~ m/tv.code$/) {
	$to->print(qq{\#include "$opt{p}tv.h"\n});
	$to->print("#define _TV_SNEAKY_ON_\n");
	$to->print(qq{\#include "$opt{p}tvpriv.h"\n});
    }
    $to->print(qq{\#line 1\n});
    my $l = join('', $fh->getlines);
    while (my ($k,$v)=each %sym) {
	$l =~ s/\b $k \b/$v/gx;
    }
    $to->print($l);
    $fh->close;
    $to->close;
    print "$f -> $fmap{$f}\n";
}
print "Done!\n";
