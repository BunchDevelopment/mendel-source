'''
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
'''


import io
import re
import os
import sys

from paramiko.rsakey import RSAKey

from mdt import command
from mdt import console
from mdt import keys


class ShellCommand(command.NetworkCommand):
    '''Usage: mdt shell [<device-or-ip-address>]

Opens an interactive shell to either your preferred device or to the first
device found.

If <device-or-ip-address> is specified, shell will attempt to connect to that
device name or directly to the IP address provided instead.

Variables used:
    preferred-device    - set this to your preferred device name to connect
                          to by default if no <devicename> is provided on the
                          command line. Can be set to an IPv4 address to bypass
                          the mDNS lookup.
    username            - set this to the username that should be used to
                          connect to a device with. Defaults to 'mendel'.
    password            - set this to the password to use to login to a new
                          device with. Defaults to 'mendel'. Only used
                          during the initial setup phase of pushing an SSH
                          key to the board.

If no SSH key is available on disk (ie: you didn't run genkey before running
shell), this will implicitly run genkey for you. Additionally, shell will
attempt to connect to a device by doing the following:

  1. Attempt a connection using your SSH key only, with no password.
  2. If the connection attempt failed due to authentication, will
     attempt to push the key to the device by using the default
     login credentials in the 'username' and 'password' variables.
  3. Installs your SSH key to the device after logging in.
  4. Disconnects and reconnects using the SSH key.
'''

    def preConnectRun(self, args):
        if len(args) > 2:
            print("Usage: mdt shell [<device-or-ip-address>]")
            return False

        if len(args) == 2:
            self.device = args[1]

        return True

    def runWithClient(self, client, args):
        channel = client.openShell()
        cons = console.Console(channel, sys.stdin)
        return cons.run()


class ExecCommand(command.NetworkCommand):
    '''Usage: mdt exec [<shell-command...>]

Opens a non-interactive shell to either your preferred device or to the first
device found.

Variables used:
    preferred-device    - set this to your preferred device name to connect
                          to by default if no <devicename> is provided on the
                          command line. Can be set to an IPv4 address to bypass
                          the mDNS lookup.
    username            - set this to the username that should be used to
                          connect to a device with. Defaults to 'mendel'.
    password            - set this to the password to use to login to a new
                          device with. Defaults to 'mendel'. Only used
                          during the initial setup phase of pushing an SSH
                          key to the board.

If no SSH key is available on disk (ie: you didn't run genkey before running
shell), this will implicitly run genkey for you. Additionally, shell will
attempt to connect to a device by doing the following:

  1. Attempt a connection using your SSH key only, with no password.
  2. If the connection attempt failed due to authentication, will
     attempt to push the key to the device by using the default
     login credentials in the 'username' and 'password' variables.
  3. Installs your SSH key to the device after logging in.
  4. Disconnects and reconnects using the SSH key.
'''
    def runWithClient(self, client, args):
        channel = client.shellExec(' '.join(args[1:]), allocPty=True)
        cons = console.Console(channel, sys.stdin)
        return cons.run()


class RebootCommand(command.NetworkCommand):
    def runWithClient(self, client, args):
        channel = client.shellExec("sudo reboot", allocPty=True)
        cons = console.Console(channel, sys.stdin)
        return cons.run()


class RebootBootloaderCommand(command.NetworkCommand):
    def runWithClient(self, client, args):
        channel = client.shellExec("sudo reboot-bootloader", allocPty=True)
        cons = console.Console(channel, sys.stdin)
        return cons.run()


class PushKeyCommand(command.NetworkCommand):
    '''Usage: mdt pushkey [<path-to-ssh-public-key>]

Copies an SSH public key provided to the device's ~/.ssh/authorized_keys
file. If an MDT private key is provided, will push the public half of that key
to the device's authorized_keys file. If no public key is provided, attempts to
push MDTs previously generated public key from ~/.config/mdt/keys/mdt.key.
'''

    def _pushMdtKey(self, client):
        print('Pushing {0}'.format(keys.KEYFILE_PATH))
        client.pushKey()
        print('Push complete.')
        return 0

    def _pushOtherKey(self, client, keyfile):
        sftp = client.openSftp()

        if not os.path.exists(keyfile):
            print("Can't copy {0}: no such file or directory.".format(keyfile))
            return 1

        source_key = ''
        with open(keyfile, 'r') as fp:
            source_key = fp.readline()

        # Paramiko RSA private key -- get the public part by converting
        if source_key.startswith('-----BEGIN RSA PRIVATE KEY-----'):
            pkey = RSAKey.from_private_key_file(keyfile)
            source_key = keys.GenerateAuthorizedKeysLine(pkey)

        try:
            sftp.chdir('/home/mendel/.ssh')
        except FileNotFoundError as e:
            sftp.mkdir('/home/mendel/.ssh', mode=0o700)

        with sftp.open('/home/mendel/.ssh/authorized_keys', 'a+b') as fp:
            fp.write(source_key)

        print("Key {0} pushed.".format(keyfile))
        return 0

    def runWithClient(self, client, args):
        key_to_push = None

        # No arguments? Let the usual client push take effect.
        if len(args) == 1:
            return self._pushMdtKey(client)

        source_keyfile = args[1]
        print('Pushing {0}'.format(source_keyfile))
        return self._pushOtherKey(client, source_keyfile)


class ResetKeysCommand(command.NetworkCommand):
    '''Usage: mdt resetkeys <device-or-ip-address>

Resets a device to it's pre-MDT state by removing all MDT keys and restarting
the mdt-keymaster on the device so that new keys can be pushed again.'''

    def preConnectRun(self, args):
        if len(args) != 2:
            print("Usage: mdt resetkeys <device-or-ip-address>")
            return False

        if len(args) == 2:
            self.device = args[1]

        return True

    def runWithClient(self, client, args):
        # Setup this session now, since once we remove the key from
        # authorized_keys, we won't be able to use execSession.
        channel = client.openChannel()

        sftp = client.openSftp()
        try:
            sftp.chdir('/home/mendel/.ssh')
        except FileNotFoundError as e:
            print('No keys were previously pushed to the board.')
        else:
            lines = []

            with sftp.open('/home/mendel/.ssh/authorized_keys', 'r') as fp:
                lines = fp.readlines()

            with sftp.open('/home/mendel/.ssh/authorized_keys', 'w') as fp:
                for line in lines:
                    if ' mdt' not in line:
                        print('wrote: {0}'.format(line))
                        fp.write(line)

        channel.exec_command("sudo systemctl restart mdt-keymaster")
        cons = console.Console(channel, sys.stdin)
        try:
            cons.run()
        except console.ConnectionClosedError as e:
            if e.exit_code:
                print('`systemctl restart mdt-keymaster` exited with code {0}'.format(e.exit_code))
                print('Your device may be in an inconsistent state. Verify using')
                print('the serial console.')
            else:
                print('Successfully reset {0}'.format(self.device))
            return e.exit_code
