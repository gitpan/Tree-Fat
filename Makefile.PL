use ExtUtils::MakeMaker;

my $testmode = 0;

my @tvlib = (qw/tv.code tv.seek tv.private tv.public tv.sym tv.setup
	     tvcommon.h tvcommon.c tvcommon0.h/);

@OBJ = ();
@PREREQ = ();
@FLAGS = ();
unlink "tietv.tmpl", "tvcommon0.h";
if ($testmode) {
    warn "...setting symlinks for testing\n";
    symlink "setup/tv.test", "tietv.tmpl";
    symlink "setup/tvcommon0.test", "tvcommon0.h";
    push(@OBJ, qw(cover1.o cover2.o ccov_registry.o));
    push(@PREREQ, 'Test' => 0.04, 'Devel::CCov' => 0.08, 'Time::HiRes' => '01.16');
    push(@FLAGS, '-g');
} else {
    warn "...setting symlinks for launch\n";
    symlink "setup/tv.prod", "tietv.tmpl";
    symlink "setup/tvcommon0.prod", "tvcommon0.h";
    push(@OBJ, qw(tietv.o tvcommon.o));
}

my $prof = '-fprofile-arcs -ftest-coverage';

WriteMakefile(
	      NAME		=> 'Tree::Fat',
	      PREREQ_PM		=> { Test => 0.03, @PREREQ },
	      EXE_FILES		=> [qw(tvgen.pl)],
	      OPTIMIZE		=> join(' ', '-DDEBUGGING', '-O2', '-I.', @FLAGS),

	      VERSION_FROM	=> 'Fat.pm',
	      OBJECT		=> join(' ', qw(Fat.o), @OBJ),
	      PM		=> { 
				    'Fat.pm' => '$(INST_LIBDIR)/Fat.pm',
				    (map { $_=>'$(INST_LIBDIR)/Fat/'.$_ } @tvlib)
				   },
              dist		=> {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
	      macro		=> { 
				    #MAP_LINKCMD
      PURIFY => '/usr/local/bin/purify -always-use-cache-dir -cache-dir=/tmp/pure $(CC)', 
      QUANTIFY => 'quantify -always-use-cache-dir -cache-dir=/tmp/pure $(CC)',
				   },
);

sub MY::postamble {
    '
tvgen.pl :: pm_to_blib

Fat.xs :: tietv.h

tietv.c tietvpriv.h tietvpub.h tietv.h :: $(INST_SCRIPT)/tvgen.pl tietv.tmpl
	$(PERL) -Mblib $(INST_SCRIPT)/tvgen.pl -t -p tie

cover1.c :: tvcommon.c
	ccovinstrument -c tvcommon.c -o $*.c -e $*.err

cover2.c :: tietv.c
	ccovinstrument -c tietv.c -o $*.c -e $*.err

ccov_registry$(OBJ_EXT): .ccov-timestamp
	ccovinstrument -r
	$(CCCMD) $(CCCDLFLAGS) $*.c

clean ::
	-rm -rf tietv*.[ch] *.ch cover[12].c *.err tvcommon0.h tietv.tmpl
	-rm -f ccov_registry.* .ccov-timestamp

';
}

#sub MY::makeaperl {
#    my $s = shift->MY::SUPER::makeaperl(@_);
#    $s =~ s/^MAP_LINKCMD.*$/MAP_LINKCMD = \$(PURIFY)/;
#    $s;
#}

__END__


