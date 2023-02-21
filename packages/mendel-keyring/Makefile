mendel-keyring.gpg: cloud-key.gpg linux_signing_key.pub gke_signing_key.gpg
	gpg --no-keyring --import-options import-export --import $^ > $@

build: mendel-keyring.gpg

install: build
	install -d $(DESTDIR)/etc/apt/trusted.gpg.d/
	cp mendel-keyring.gpg $(DESTDIR)/etc/apt/trusted.gpg.d/

clean:
	rm -f mendel-keyring.gpg

.PHONY: build install clean
