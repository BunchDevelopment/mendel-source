#!/usr/bin/env python3

"""MDT - The Mendel Development Tool

This is the main CLI dispatch routine that teases out the command line and runs
the appropriate command.


Copyright 2019 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""

import socket
import sys

try:
    import paramiko
    import zeroconf
except ImportError:
    sys.stderr.write("Couldn't load paramiko or zeroconf -- "
                     "perhaps you need to install them?\r\n")
    sys.stderr.write("On Debian derivatives, 'apt-get install "
                     "python3-paramiko python3-zeroconf'.\r\n")
    sys.exit(1)

from mdt import config
from mdt import devices
from mdt import files
from mdt import keys
from mdt import shell
import mdt


# Stop deprecation warnings from Python's crypto libs for silly APIs like sign
# and verify and ecdh junk that we don't even use, nor can we fix.
import warnings
warnings.filterwarnings(
    action='ignore',
    message='.*signer and verifier have been deprecated.*',
    module='.*paramiko.rsakey')
warnings.filterwarnings(
    action='ignore',
    message='.*encode_point has been deprecated on EllipticCurvePublicNumbers.*',
    module='.*paramiko.kex_ecdh_nist')
warnings.filterwarnings(
    action='ignore',
    message='.*Support for unsafe construction of public numbers.*',
    module='.*paramiko.kex_ecdh_nist')


MDT_USAGE_HELP = '''
Usage: mdt <subcommand> [<options>]

Where <subcommand> may be one of the following:
    help              - this command, gets help on another command.
    devices           - lists all detected devices.
    wait-for-device   - waits for a device to be discovered on the network
    get               - gets an MDT variable value
    set               - sets an MDT variable value
    clear             - clears an MDT variable
    genkey            - generates an SSH key for connecting to a device
    pushkey           - pushes an SSH public key to a device
    setkey            - imports a PEM-format SSH private key into the MDT
                        keystore
    resetkeys         - removes all keys from the given board and resets key
                        authentication to factory defaults
    shell             - opens an interactive shell to a device
    exec              - runs a shell command and returns the output and the
                        exit code
    install           - installs a Debian package using mdt-install-package on
                        the device
    push              - pushes a file (or files) to the device
    pull              - pulls a file (or files) from the device
    reboot            - reboots a device
    reboot-bootloader - reboots a device into the bootloader
    version           - prints which version of MDT this is

Use "mdt help <subcommand>" for more details.
'''


class HelpCommand:
    '''Usage: mdt help [<subcommand>]

Gets additional information about a given subcommand, or returns a summary
of subcommands available.
'''

    def run(self, args):
        if len(args) <= 1:
            print(MDT_USAGE_HELP)
            return 1

        subcommand = args[1].lower()

        if subcommand in COMMANDS:
            command = COMMANDS[subcommand]
            if command.__doc__:
                print(command.__doc__)
            else:
                print("No help is available for subcommand '{0}' "
                      "-- please yell at the developers. :)".format(subcommand))
        else:
            print("Unknown subcommand '{0}' -- try 'mdt help' for a list".format(subcommand))


class VersionCommand:
    '''Usage: mdt version

Prints the MDT version.
'''

    def run(self, args):
        print("MDT version {0}".format(mdt.__version__))


COMMANDS = {
    'clear': config.ClearCommand(),
    'devices': devices.DevicesCommand(),
    'exec': shell.ExecCommand(),
    'genkey': keys.GenKeyCommand(),
    'get': config.GetCommand(),
    'help': HelpCommand(),
    'install': files.InstallCommand(),
    'pull': files.PullCommand(),
    'push': files.PushCommand(),
    'pushkey': shell.PushKeyCommand(),
    'reboot': shell.RebootCommand(),
    'reboot-bootloader': shell.RebootBootloaderCommand(),
    'resetkeys': shell.ResetKeysCommand(),
    'set': config.SetCommand(),
    'setkey': keys.SetKeyCommand(),
    'shell': shell.ShellCommand(),
    'wait-for-device': devices.DevicesWaitCommand(),
    'version': VersionCommand(),
}


def main():
    try:
        if len(sys.argv) <= 1:
            exit(COMMANDS['help'].run([]))
        else:
            command = sys.argv[1].lower()

        if command == '--help':
            command = 'help'

        if command in COMMANDS:
            command = COMMANDS[command]
            exit(command.run(sys.argv[1:]))

        print("Unknown command '{0}': try 'mdt help'".format(command))
        return 1

    except KeyboardInterrupt:
        print()
        exit(1)


if __name__ == '__main__':
    main()
