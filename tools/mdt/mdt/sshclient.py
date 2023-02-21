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


import http.client
import os
import socket
import time
import fnmatch

import paramiko
from paramiko.ssh_exception import AuthenticationException, SSHException
from paramiko.client import AutoAddPolicy

from mdt import config
from mdt import discoverer
from mdt import keys


KEYMASTER_PORT = 41337


class KeyPushError(Exception):
    pass


class DefaultLoginError(Exception):
    pass


class NonLocalDeviceError(Exception):
    pass


class SshClient:
    def __init__(self, device, address):
        self.config = config.Config()
        self.keystore = keys.Keystore()

        self.device = device
        self.address = address

        self.username = self.config.username()
        self.password = self.config.password()
        self.envWhitelist = self.config.envWhitelist()

        if not self.maybeGenerateSshKeys():
            return False

        self.client = paramiko.SSHClient()
        self.client.set_missing_host_key_policy(AutoAddPolicy())

    def shouldPushKey(self):
        try:
            self.client.connect(
                self.address,
                username=self.username,
                pkey=self.keystore.key(),
                allow_agent=False,
                look_for_keys=False,
                compress=True)
        except AuthenticationException as e:
            return True
        except (SSHException, socket.error) as e:
            raise e
        finally:
            self.client.close()

    def _pushKeyViaKeymaster(self):
        if not self.address:
            raise discoverer.DeviceNotFoundError()

        if not self.address.startswith('192.168.10'):
            raise NonLocalDeviceError()

        connection = http.client.HTTPConnection(self.address, KEYMASTER_PORT)
        try:
            key_line = keys.GenerateAuthorizedKeysLine(self.keystore.key())
            connection.request('PUT', '/', key_line + '\r\n')
            response = connection.getresponse()
        except ConnectionRefusedError as e:
            print()
            print("Couldn't connect to keymaster on {0}: {1}.".format(self.device, e))
            print()
            print("Did you previously connect from a different machine? If so,\n"
                  "mdt-keymaster will not be running as it only accepts a single key.\n")
            print("You will need to either:\n"
                  "   1) Remove the key from /home/mendel/.ssh/authorized_keys on the\n"
                  "      device via the serial console\n"
                  "\n- or -\n\n"
                  "   2) Copy the mdt private key from your home directory on this host\n"
                  "      in ~/.config/mdt/keys/mdt.key to the first machine and use\n"
                  "      'mdt pushkey mdt.key' to add that key to the device's\n"
                  "      authorized_keys file.")
            print()
            raise KeyPushError(e)
        except ConnectionError as e:
            raise KeyPushError(e)
        finally:
            connection.close()

    def _pushKeyViaDefaultLogin(self):
        try:
            self.client.connect(
                    self.address,
                    username=self.username,
                    password=self.password,
                    allow_agent=False,
                    look_for_keys=False,
                    compress=True)
        except AuthenticationException as e:
            raise DefaultLoginError(e)
        except (SSHException, socket.error) as e:
            raise KeyPushError(e)
        else:
            key_line = self._generateAuthorizedKeysLine()
            self.client.exec_command('mkdir -p $HOME/.ssh')
            self.client.exec_command(
                'echo {0} >>$HOME/.ssh/authorized_keys'.format(key_line))
        finally:
            self.client.close()

    def pushKey(self):
        try:
            self._pushKeyViaKeymaster()
        except KeyPushError as e:
            print('Failed to push via keymaster -- will attempt password login as a fallback.')
            self._pushKeyViaDefaultLogin()

        time.sleep(1)

        # Ensure the key we just pushed allows us to login
        try:
            self.client.connect(
                self.address,
                username=self.username,
                pkey=self.keystore.key(),
                allow_agent=False,
                look_for_keys=False,
                compress=True)
        except AuthenticationException as e:
            raise KeyPushError(e)
        except (SSHException, socket.error) as e:
            raise KeyPushError(e)
        finally:
            self.client.close()

    def maybeGenerateSshKeys(self):
        if not self.keystore.key():
            print('Looks like you don\'t have a private key yet. '
                  'Generating one.')

            if not self.keystore.generateKey():
                print('Unable to generate private key.')
                return False

        return True

    def _generateEnvironment(self):
        environment = {}
        for pattern in self.envWhitelist.split(' '):
            for name, value in os.environ.items():
                if fnmatch.fnmatch(name, pattern):
                    environment[name] = value
        return environment

    def openShell(self):
        term = os.getenv("TERM", default="dumb")
        env = self._generateEnvironment()
        width, height = os.get_terminal_size()

        if self.shouldPushKey():
            print("Key not present on {0} -- pushing".format(self.device))
            self.pushKey()

        self.client.connect(
            self.address,
            username=self.username,
            pkey=self.keystore.key(),
            allow_agent=False,
            look_for_keys=False,
            compress=True)

        # FIXME(jtgans): Add environment support once all major distributions we
        # support have added in Paramiko v2.1.x or newer.
        return self.client.invoke_shell(term=term, width=width, height=height)

    def openChannel(self, allocPty=False):
        if self.shouldPushKey():
            print("Key not present on {0} -- pushing".format(self.device))
            self.pushKey()

        self.client.connect(
            self.address,
            username=self.username,
            pkey=self.keystore.key(),
            allow_agent=False,
            look_for_keys=False,
            compress=True)

        session = self.client.get_transport().open_session()
        if allocPty:
            term = os.getenv("TERM", default="vt100")
            width, height = os.get_terminal_size()
            session.get_pty(term=term, width=width, height=height)

        return session

    def shellExec(self, cmd, allocPty=False):
        channel = self.openChannel(allocPty=allocPty)
        channel.exec_command(cmd)
        return channel

    def openSftp(self):
        if self.shouldPushKey():
            print("Key not present on {0} -- pushing".format(self.device))
            self.pushKey()

        self.client.connect(
            self.address,
            username=self.username,
            pkey=self.keystore.key(),
            allow_agent=False,
            look_for_keys=False,
            compress=True)

        session = self.client.open_sftp()
        return session

    def close(self):
        self.client.close()
