use ExtUtils::MakeMaker;

my @tvlib = qw/tv.code tv.seek tv.private tv.public tv.sym tv.setup/;

my $Testing = 1;
WriteMakefile(
	      NAME		=> 'Tree::Fat',
	      PREREQ_PM		=> {
				    Text::Balanced => '1.24',
				    Time::HiRes => '01.16',
				   },
#	      LD => '/usr/local/bin/purify -always-use-cache-dir -cache-dir=/tmp/pure gcc',
	      EXE_FILES		=> [qw(tvgen.pl)],
	      OPTIMIZE		=> '-g -DDEBUGGING',

	      VERSION_FROM	=> 'Fat.pm',
	      OBJECT		=> 'tietv.o Fat.o '.($Testing?'debcover.o':''),
	      PM		=> { 
				    'Fat.pm' => '$(INST_LIBDIR)/Fat.pm',
				    (map { $_=>'$(INST_LIBDIR)/Fat/'.$_ } @tvlib)
				   },
              dist		=> {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
);

sub MY::postamble {
    '
tvgen.pl :: pm_to_blib

debtv.c debtvpriv.h debtvpub.h debtv.h :: $(INST_SCRIPT)/tvgen.pl debtv.tmpl
	$(PERL) -Mblib $(INST_SCRIPT)/tvgen.pl -p deb

debcover.c :: ccovscan.pl debtv.c
	$(PERL) ./ccovscan.pl debtv.c > $@

tietv.c tietvpriv.h tietvpub.h tietv.h :: $(INST_SCRIPT)/tvgen.pl tietv.tmpl
	$(PERL) -Mblib $(INST_SCRIPT)/tvgen.pl -p tie

Fat.xs :: debtv.h tietv.h

clean ::
	rm -rf debcover.* debtv*.c debtv*.h avtv*.c avtv*.h tietv*.c tietv*.h

';
}

__END__


