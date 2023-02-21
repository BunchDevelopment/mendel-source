#!/usr/bin/python

import deb822

import os
import sys

NODE_TEMPLATE = """"{0}" [shape=box, label="{0}"];"""
EDGE_TEMPLATE = """"{0}" -> "{1}";"""

if __name__ == '__main__':
    rootdir = os.getenv("ROOTDIR")
    if rootdir is None:
        print("ROOTDIR is not defined. Did you source build/setup.sh?")
        sys.exit(1)

    print("""digraph package_dependencies {""")

    packagerootdir = rootdir + '/packages'
    for packagedir in os.listdir(packagerootdir):
        with open(packagerootdir + '/' + packagedir + '/debian/control') as fp:
            for paragraph in deb822.Deb822.iter_paragraphs(fp):
                if paragraph.has_key('Package'):
                    package_name = paragraph['Package']
                    print(NODE_TEMPLATE.format(package_name))
                    if paragraph.has_key('Depends'):
                        for depended_package in paragraph['Depends'].split(','):
                            depended_package = depended_package.rstrip('\n')
                            depended_package = depended_package.strip('\n')
                            depended_package = depended_package.strip(' ')
                            depended_package = depended_package.rstrip(' ')
                            print(EDGE_TEMPLATE.format(package_name, depended_package))

    print("""}""")
