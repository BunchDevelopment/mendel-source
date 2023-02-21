# Version Numbering

## Upstream

<software-version>[-<upstream-package-version>]mendel<package-version>

upstream-package-version is optional if upstream doesn't have a package version.
If it is present, it must be prefixed with a single dash.

## Mendel packages

<software-version>-<package-version>

# Package Naming

Package names should be using a methodical naming convention.

Board specific packages should be named "<boardname>-board-<packagename>". In
the case of enterprise, we use "imx" as the board name for historical reasons.

Python packages that provide libraries should use the upstream Debian naming
with "python3-" or "python-" as the package name.

Mendel specific packages should be named "mendel-<packagename>".
