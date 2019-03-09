.POSIX:
.SUFFIXES:

NAME=prometheus-netscanner
# VERSION=$(shell git describe --always --match v[0-9]* HEAD | cut -c2-)
VERSION=0.0.1
OUT_DIR=build
PACKAGE_DIR=$(OUT_DIR)/$(NAME)-$(VERSION)

$(OUT_DIR):
	@mkdir -p "$@"

$(PACKAGE_DIR): \
	$(PACKAGE_DIR)/DEBIAN \
	$(PACKAGE_DIR)/lib/systemd/system/$(NAME).service \
	$(PACKAGE_DIR)/lib/systemd/system/$(NAME).timer \
	$(PACKAGE_DIR)/usr/bin/scan.sh \
	$(PACKAGE_DIR)/etc/sudoers.d/promscan \

	@touch "$@"

$(PACKAGE_DIR)/DEBIAN: \
	$(PACKAGE_DIR)/DEBIAN/conffile \
	$(PACKAGE_DIR)/DEBIAN/control \
	$(PACKAGE_DIR)/DEBIAN/postinst \
	$(PACKAGE_DIR)/DEBIAN/postrm \
	$(PACKAGE_DIR)/DEBIAN/prerm \

	@touch "$@"

$(PACKAGE_DIR)/DEBIAN/control: debian/control
	(cat debian/control && echo -n 'Version: ' && echo "${VERSION}") > "$@"

$(PACKAGE_DIR)/DEBIAN/%: debian/%
	@mkdir -p "$(dir $@)"
	cp -p "debian/$*" "$@"

$(PACKAGE_DIR)/lib/systemd/system/%: sys/lib/systemd/system/%
	@mkdir -p $(PACKAGE_DIR)/lib/systemd/system
	cp -r "$<" "$@"

$(PACKAGE_DIR)/usr/bin/scan.sh: scan.sh
	@mkdir -p "$(dir $@)"
	cp -p scan.sh "$@"

$(PACKAGE_DIR)/etc/sudoers.d/promscan: sys/etc/sudoers.d/promscan
	@mkdir -p "$(dir $@)"
	cp -p "$<" "$@"

.PHONY: deb
deb: $(PACKAGE_DIR).deb

$(PACKAGE_DIR).deb: $(PACKAGE_DIR)
	chmod 755 $(PACKAGE_DIR)/DEBIAN/postinst
	chmod 755 $(PACKAGE_DIR)/DEBIAN/postrm
	chmod 755 $(PACKAGE_DIR)/DEBIAN/prerm
	fakeroot dpkg-deb --build "${PACKAGE_DIR}"

.PHONY: clean
clean:
	rm -rf "$(OUT_DIR)"
