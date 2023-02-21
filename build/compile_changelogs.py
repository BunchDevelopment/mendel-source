#!/usr/bin/python3

import sys

from debian import changelog

CHANGELOG_FORMAT = '''{0} ({1}): {2}'''

if __name__ == '__main__':
    for filename in sys.stdin:
        filename = filename[0:-1]
        with open(filename, 'r') as fp:
            clog = changelog.Changelog(file=fp)
            latest_block = clog[0]
            print(CHANGELOG_FORMAT.format(
                latest_block.package,
                latest_block.version,
                '\n'.join(latest_block.changes())))
