# Default profile for Mendel Linux.
Profile: mendel/main
Extends: debian/main
Disable-Tags: empty-debian-diff,
 executable-not-elf-or-script,
 binary-without-manpage,
 script-with-language-extension,
 missing-license-paragraph-in-dep5-copyright,
 source-is-missing, arch-independent-package-contains-binary-or-object,
 arch-dependent-file-in-usr-share, unstripped-binary-or-object,
 statically-linked-binary, missing-depends-line,
 source-nmu-has-incorrect-version-number, changelog-should-mention-nmu,
 newer-standards-version, maintainer-address-causes-mail-loops-or-bounces,
 spelling-error-in-readme-debian, new-package-should-close-itp-bug
