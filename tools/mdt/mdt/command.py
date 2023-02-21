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


import re
import os
import socket

from time import sleep

from paramiko.ssh_exception import SSHException

from mdt import config
from mdt import console
from mdt import discoverer
from mdt import sshclient


IP_ADDR_REGEX = re.compile('[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')


class NetworkCommand:
    def __init__(self):
        self.config = config.Config()
        self.discoverer = discoverer.Discoverer(self)
        self.device = self.config.preferredDevice()
        self.address = None

    def add_device(self, hostname, address):
        if not self.device:
            self.device = hostname
            self.address = address
        elif self.device == hostname:
            self.address = address

    def run(self, args):
        if not self.preConnectRun(args):
            return 1

        # User provided an IP address to connect to instead -- we should skip
        # discovery.
        if self.device and IP_ADDR_REGEX.match(self.device):
            self.address = self.device

        if not self.address:
            if self.device:
                print('Waiting for device {0}...'.format(self.device))
            else:
                print('Waiting for a device...')
            self.discoverer.discover()

        if not self.address:
            if not self.device:
                print('Unable to find any devices on your local network segment.')
            else:
                print('Unable to find a device called {0} on your local network segment.'.format(self.device))
            return 1

        client = None
        try:
            print('Connecting to {0} at {1}'.format(self.device, self.address))
            client = sshclient.SshClient(self.device, self.address)
            return self.runWithClient(client, args)
        except sshclient.KeyPushError as e:
            print("Unable to push keys to the device: {0}".format(e))
            return 1
        except sshclient.DefaultLoginError as e:
            print("Can't login using default credentials: {0}".format(e))
            return 1
        except sshclient.NonLocalDeviceError as e:
            print()
            print("It looks like you're trying to connect to a device that isn't connected\n"
                  "to your workstation via USB and doesn't have the SSH key this MDT generated.\n"
                  "To connect with `mdt shell` you will need to first connect to your device\n"
                  "ONLY via USB.")
            print()
            print("Cowardly refusing to attempt to push a key to a public machine.\n")
            return 1
        except SSHException as e:
            print("Couldn't establish ssh connection to device: {0}".format(e))
            return 1
        except socket.error as e:
            print("Couldn't establish ssh connection to device: "
                  "socket error: {0}".format(e))
            return 1
        except console.SocketTimeoutError as e:
            print("\r\nConnection to {0} at {1} closed: "
                  "socket timeout".format(self.device, self.address))
            return 1
        except console.ConnectionClosedError as e:
            if e.exit_code:
                print("\r\nConnection to {0} at {1} closed with exit code "
                      "{2}".format(self.device, self.address, e.exit_code))
            else:
                print("\r\nConnection to {0} at {1} "
                      "closed".format(self.device, self.address))
            return e.exit_code
        finally:
            if client:
                client.close()

    def runWithClient(self, client, args):
        return 1

    def preConnectRun(self, args):
        return True
