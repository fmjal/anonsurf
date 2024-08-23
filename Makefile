os_name = "$(shell cat /etc/os-release | grep "^ID=" | cut -d = -f 2)"
nim_args = "-b:c --benchmarkVM:on --profileVM:on --verbosity:3 --parallelBuild:2  -X:off --showAllMismatches:on --opt:speed --debugger:native -f:on --stackTrace:off --lineTrace:off --tlsEmulation:on --embedsrc:off --implicitStatic:on --trmacros:on --multimethod:on --hotCodeReloading:on --excessiveStackTrace:off --stackTraceMsgs:off --noImportdoc:on  --docCmd:skip --nimcache:/tmp"

all: build install

clean:
	rm -rf bin

uninstall:
	# Remove config files
	rm -rf /etc/anonsurf/
	# Remove daemon scripts and some other binaries
	rm -rf /usr/lib/anonsurf/
	# Remove binaries
	rm /usr/bin/anonsurf
	rm /usr/bin/anonsurf-gtk
	# Remove systemd unit
	rm /lib/systemd/system/anonsurfd.service
	# Remove launchers
	rm /usr/share/applications/anonsurf*.desktop

build-parrot:
	# Compile binary on parrot's platform. libnim-gintro-dev is required.
	# Gintro 0.9.8 is required
	mkdir -p bin/
	nim c ${nim_args} --out:bin/dnstool -d:release src/nim/dnstool/dnstool.nim
	nim c ${nim_args} --out:bin/make-torrc -d:release src/nim/anonsurf/make_torrc.nim
	nim c ${nim_args} --out:bin/anonsurf-gtk -p:/usr/include/nim/ -d:release src/nim/anonsurf/AnonSurfGTK.nim
	nim c ${nim_args} --out:bin/anonsurf -p:/usr/include/nim/ -d:release src/nim/anonsurf/AnonSurfCli.nim

build:
	# Build on other system. nimble install gintro is required
	# Note: AnonSurf 3.3.2 was made with Gintro 0.9.6, and newer version comes with gintro 0.9.8 pre-release 
	mkdir -p bin/
	nim c ${nim_args} --out:bin/dnstool -d:release src/nim/dnstool/dnstool.nim
	nim c ${nim_args} --out:bin/make-torrc -d:release src/nim/anonsurf/make_torrc.nim
	nim c ${nim_args} --out:bin/anonsurf-gtk -d:release src/nim/anonsurf/AnonSurfGTK.nim
	nim c ${nim_args} --out:bin/anonsurf -d:release src/nim/anonsurf/AnonSurfCli.nim

install:
	# Create all folders
	mkdir -p $(DESTDIR)/etc/anonsurf/
	mkdir -p $(DESTDIR)/usr/lib/anonsurf/
	mkdir -p $(DESTDIR)/usr/bin/
	mkdir -p $(DESTDIR)/usr/share/applications/
	mkdir -p $(DESTDIR)/lib/systemd/system/

	# Copy binaries to system
	cp bin/anonsurf $(DESTDIR)/usr/bin/anonsurf
	cp bin/anonsurf-gtk $(DESTDIR)/usr/bin/anonsurf-gtk
	cp bin/dnstool $(DESTDIR)/usr/bin/dnstool
	cp bin/make-torrc $(DESTDIR)/usr/lib/anonsurf/make-torrc
	cp scripts/* $(DESTDIR)/usr/lib/anonsurf/

	# Copy launchers
	if [ os_name = "parrot" ]; then \
		cp launchers/anon-change-identity.desktop $(DESTDIR)/usr/share/applications/; \
		cp launchers/anon-surf-start.desktop $(DESTDIR)/usr/share/applications/; \
		cp launchers/anon-surf-stop.desktop $(DESTDIR)/usr/share/applications/; \
		cp launchers/anon-check-ip.desktop $(DESTDIR)/usr/share/applications/; \
		cp launchers/anon-gui.desktop $(DESTDIR)/usr/share/applications/; \
	else \
		cp launchers/non-native/*.desktop $(DESTDIR)/usr/share/applications/; \
	fi

	# Copy configs
	cp configs/bridges.txt $(DESTDIR)/etc/anonsurf/.
	cp configs/onion.pac $(DESTDIR)/etc/anonsurf/.

	# Copy daemon service
	cp sys-units/anonsurfd.service $(DESTDIR)/lib/systemd/system/anonsurfd.service
