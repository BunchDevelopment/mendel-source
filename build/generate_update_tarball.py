#!/usr/bin/python3

import argparse
import glob
import os
import re
import shutil
import subprocess
import sys
import tempfile

from apt import cache
from debian import changelog
from debian import deb822
from git import Repo

VERSION_MAP = {
    'any': 'arm64',
    'linux-any': 'arm64',
}

ARCHES = [
    'arm64',
]

def GetDebianDirectories(rootdir):
    packages_dir = os.path.join(rootdir, 'packages')
    if not os.path.exists(packages_dir):
        print('No packages directory found!')
        sys.exit(-1)
    debian_dirs = []
    for package in os.scandir(packages_dir):
        debian_dir = os.path.join(package.path, 'debian')
        if os.path.exists(debian_dir):
            debian_dirs.append(debian_dir)
    return debian_dirs

def GeneratePackageList(directory):
    package_name = os.path.split(os.path.split(directory)[0])[1]
    package_tuples = []
    with open(os.path.join(directory, 'changelog'), 'rb') as changelog_file, \
         open(os.path.join(directory, 'control')) as control_file:
        cl = changelog.Changelog(file=changelog_file)
        version = cl.get_version()

        packages = deb822.Packages.iter_paragraphs(control_file)
        for p in packages:
            if 'Source' in p:
                package_name = p['Source']
            if 'Package' in p and 'Architecture' in p:
                arches = p['Architecture']
                if arches in VERSION_MAP:
                    arches = VERSION_MAP[arches]
                arches = arches.split(' ')
                for arch in arches:
                    package_tuples.append((package_name, '%s:%s' % (p['Package'], arch), version))
    return package_tuples

def UpdateNeeded(package_name, package_version, apt_cache):
    package_name = package_name
    package = apt_cache.get(package_name)
    if package:
        return package_version > package.versions[0].version
    else:
        return True

def GetSourceDirectory(rootdir, package):
    proc = subprocess.run(['make', '-f', os.path.join(rootdir, 'build', 'Makefile'),
                          package + '-source-directory'],
                          stdout=subprocess.PIPE, universal_newlines=True)
    proc.check_returncode()
    for line in proc.stdout.split(os.linesep):
        if line.startswith('Source directory: '):
            return line.split(': ')[1]

def CheckVersionTags(rootdir, package, version):
    source_dir = os.path.join(rootdir, GetSourceDirectory(rootdir, package))
    debian_dir = os.path.join(rootdir, 'packages', package)
    source_repo = Repo(source_dir)
    debian_repo = Repo(debian_dir)
    source_tags = source_repo.git.tag('-l')
    debian_tags = debian_repo.git.tag('-l')
    str_version = str(version)
    if str_version in source_tags and str_version in debian_tags:
        print('Found tags for %s of %s. Checking out tags.' % (version, package))
        source_repo.git.checkout('tags/' + str_version)
        debian_repo.git.checkout('tags/' + str_version)
        return True
    else:
        print('Did not find tags for %s of %s.' % (version, package))
        return False


def main():
    parser = argparse.ArgumentParser(description='Find which packages are newer in the local repository than Apt')
    parser.add_argument('-rootdir', type=str, required=True)
    parser.add_argument('-sources_list', type=str, required=True)
    parser.add_argument('-package_dir', type=str, required=True)
    parser.add_argument('-output_tarball', type=str, required=True)
    args = parser.parse_args()

    # Find directories of Debian package data.
    debian_directories = GetDebianDirectories(args.rootdir)
    packages = []
    for directory in debian_directories:
        packages += GeneratePackageList(directory)

    # Check the versions of packages in the local repository,
    # and compare against the versions of packages in the apt cache.
    # If a source version that is newer than upstream is present in
    # the local source repository, check whether git tags exist for that version.
    packages_to_update = dict()
    debs_to_update = set()
    with tempfile.TemporaryDirectory() as tempdir:
        apt_dir = os.path.join(tempdir, 'etc', 'apt')
        os.makedirs(apt_dir)
        shutil.copyfile(args.sources_list, os.path.join(apt_dir, 'sources.list'))

        apt_cache = cache.Cache(rootdir=tempdir, memonly=True)
        apt_cache.update()
        apt_cache.open()

        for (package_group, package_name, version) in packages:
            if UpdateNeeded(package_name, version, apt_cache):
                if CheckVersionTags(args.rootdir, package_group, version):
                    packages_to_update[package_group] = version
                    debs_to_update.add(package_name)

        apt_cache.close()

    # Compile appropriately tagged packages for all arches.
    for package in packages_to_update:
        print('make ' + package + '...')
        for arch in ARCHES:
            proc = subprocess.run(["make", "-f", os.path.join(args.rootdir, 'build', 'Makefile'),
                                  "USERSPACE_ARCH="+arch, package], stdout=sys.stdout, stderr=sys.stderr)
            proc.check_returncode()

    # Find the set of output files corresponding to the packages we are going to upload.
    output_files = set()
    for deb in debs_to_update:
        for filename in glob.glob('%s/**/*%s*' % (args.package_dir, deb.split(':')[0])):
            output_files.add(filename)
    for package in packages_to_update:
        for filename in glob.glob('%s/**/*%s*' % (args.package_dir, package)):
            output_files.add(filename)

    # Generate a tarball appropriate for uploading containing the new packages.
    with tempfile.TemporaryDirectory() as tempdir:
        bsp_dir = os.path.join(tempdir, 'packages', 'bsp')
        core_dir = os.path.join(tempdir, 'packages', 'core')
        os.makedirs(bsp_dir)
        os.makedirs(core_dir)
        for filename in output_files:
            (path, deb_name) = os.path.split(filename)
            (_, repository) = os.path.split(path)
            if repository == 'bsp':
                shutil.copy(filename, bsp_dir)
            if repository == 'core':
                shutil.copy(filename, core_dir)
        tar_command = "tar -C %s --overwrite -czf %s packages" % (tempdir, args.output_tarball)
        proc = subprocess.run(tar_command.split(' '), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        proc.check_returncode()

if __name__ == '__main__':
    main()
