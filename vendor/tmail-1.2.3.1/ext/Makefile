#
# ext/tmail/Makefile
#

.PHONY: tmailscanner clean distclean

all: tmailscanner

tmailscanner: tmailscanner/tmail/Makefile
	cd tmailscanner/tmail; $(MAKE)

tmailscanner/tmail/Makefile: tmailscanner/tmail/extconf.rb
	cd tmailscanner/tmail; ruby extconf.rb

clean:
	cd tmailscanner/tmail; $(MAKE) clean

distclean:
	cd tmailscanner/tmail; $(MAKE) distclean

