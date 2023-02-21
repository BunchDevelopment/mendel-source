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


import os
import sys
import time

from stat import S_ISDIR

from mdt import command
from mdt import config
from mdt import console
from mdt import discoverer
from mdt import sshclient


PROGRESS_WIDTH = 45
FILENAME_WIDTH = 30


def MakeProgressFunc(full_filename, width, char='>'):
    def closure(bytes_xferred, total_bytes):
        filename = full_filename
        if len(filename) > FILENAME_WIDTH:
            filename = filename[0:FILENAME_WIDTH - 3] + '...'

        pcnt = bytes_xferred / total_bytes
        left = char * round(pcnt * width)
        right = ' ' * round((1 - pcnt) * width)
        pcnt = '%3d' % (int(pcnt * 100))
        sys.stdout.write('\r{0}% |{1}{2}| {3}'.format(
            pcnt, left, right, filename))
        sys.stdout.flush()

    return closure


class InstallCommand(command.NetworkCommand):
    '''Usage: mdt install <deb-package>

Installs a given Debian package file to the connected device via
mdt-install-package.

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

Note: if the package provided has dependencies that are not already installed on
the device, this will require internet connectivity to fetch and install those
dependencies.
'''

    def preConnectRun(self, args):
        if len(args) < 2:
            print("Usage: mdt install [<package-filename...>]")
            return False

        return True

    def runWithClient(self, client, args):
        package_to_install = args[1]
        package_filename = os.path.basename(package_to_install)
        remote_filename = os.path.join('/tmp', package_filename)

        sftp_callback = MakeProgressFunc(package_filename, PROGRESS_WIDTH)
        sftp = client.openSftp()
        sftp.put(package_to_install, remote_filename, callback=sftp_callback)
        sftp.close()
        client.close()
        print()

        channel = client.shellExec("sudo /usr/sbin/mdt-install-package {0}; "
                                   "rm -f {0}".format(remote_filename),
                                   allocPty=True)
        cons = console.Console(channel, sys.stdin)
        return cons.run()


class PushCommand(command.NetworkCommand):
    '''Usage: mdt push <local-path...> [<remote-path>]

If a directory name is provided as a local path, a directory will be created on
the device and the contents of that directory will be copied in place,
recursively.

If remote-path is omitted, push assumes you mean to push files to /home/mendel
instead.

Note that the last argument is considered to be the remote path to push to!

If remote-path is a path that exists locally, it will be considered to be a
local-path instead, and push will default to pushing to /home/mendel instead.
This can lead to surprising results, so check if your last argument exists or
not.

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
'''

    def preConnectRun(self, args):
        if len(args) < 2:
            print('Usage: mdt push <local-path...> [<remote-path>]')
            return False

        # If the last argument (remote-path) exists, assume it is a file to push
        # and the remote-path should be /home/mendel
        if os.path.exists(args[-1]):
            self.files_to_push = args[1:]
            self.destination = '/home/mendel'
        elif len(args) == 2:
            # Catch the case where the only argument given doesn't exist.
            print('{0}: No such file or directory'.format(args[1]))
            return False
        else:
            self.files_to_push = args[1:-1]
            self.destination = args[-1]

        # Convert relative paths into absolute ones for Paramiko
        if self.destination[0] != '/':
            self.destination = '/home/mendel/' + self.destination

        return True

    def maybeMkdir(self, sftp, dirname):
        try:
            sftp.stat(dirname)
        except IOError as e:
            sftp.mkdir(dirname)

    def pushDir(self, sftp, dir, destination):
        basename = os.path.basename(dir)
        destination = os.path.normpath(os.path.join(destination, basename))
        self.maybeMkdir(sftp, destination)

        for path, subdirs, files in os.walk(dir):
            relpath = os.path.relpath(path, start=dir)
            remote_path = os.path.join(destination, relpath)

            for name in subdirs:
                remote_name = os.path.join(remote_path, name)
                self.maybeMkdir(sftp, remote_name)

            for name in files:
                self.pushFile(sftp,
                              os.path.join(path, name),
                              remote_path)

    def pushFile(self, sftp, file, destination):
        destination = os.path.normpath(destination)
        self.maybeMkdir(sftp, destination)

        base_filename = os.path.basename(file)
        remote_path = os.path.join(destination, base_filename)

        sftp_callback = MakeProgressFunc(file, PROGRESS_WIDTH)
        sftp_callback(0, 1)
        sftp.put(file, remote_path, callback=sftp_callback)
        sftp_callback(1, 1)

        print()

    def runWithClient(self, client, args):
        sftp = client.openSftp()

        try:
            for file in self.files_to_push:
                file = os.path.normpath(file)
                if os.path.isdir(file):
                    self.pushDir(sftp, file, self.destination)
                else:
                    self.pushFile(sftp, file, self.destination)
        except IOError as e:
            print("Couldn't upload file to device: {0}".format(e))
            return 1
        finally:
            sftp.close()

        return 0


class PullCommand(command.NetworkCommand):
    '''Usage: mdt pull <filename...> <local-destination-path>

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

Pulls (copies) a set of files from the remote device to a local path.
'''

    def preConnectRun(self, args):
        if len(args) < 3:
            print("Usage: mdt pull <filename...> <local-destination-path>")
            return False

        return True

    def sftpWalk(self, sftp, remote_dir):
        dirs_to_walk = [remote_dir]
        for dir in dirs_to_walk:
            entries = sftp.listdir_attr(dir)
            dirs = []
            files = []

            for entry in entries:
                if S_ISDIR(entry.st_mode):
                    dirs.append(entry.filename)
                    dirs_to_walk.append(dir + '/' + entry.filename)
                else:
                    files.append(entry.filename)

            yield (dir, dirs, files)

    def maybeMkdir(self, dir):
        if not os.path.exists(dir):
            os.mkdir(dir)

    def pullDir(self, sftp, remote_dir, destination):
        basename = os.path.basename(remote_dir)
        destination = os.path.normpath(os.path.join(destination, basename))
        self.maybeMkdir(destination)

        for path, subdirs, files in self.sftpWalk(sftp, remote_dir):
            relpath = os.path.relpath(path, start=remote_dir)
            local_path = os.path.join(destination, relpath)

            for name in subdirs:
                local_name = os.path.join(local_path, name)
                self.maybeMkdir(local_name)

            for name in files:
                self.pullFile(sftp, path + '/' + name, local_path)

    def pullFile(self, sftp, remote_file, destination):
        base_filename = os.path.basename(remote_file)
        destination_filename = os.path.join(destination, base_filename)

        sftp_callback = MakeProgressFunc(remote_file, PROGRESS_WIDTH, char='<')
        sftp_callback(0, 1)
        sftp.get(remote_file, destination_filename, callback=sftp_callback)
        sftp_callback(1, 1)

        print()

    def runWithClient(self, client, args):
        files_to_pull = args[1:-1]
        destination = args[-1]

        try:
            sftp = client.openSftp()
            for file in files_to_pull:
                stat_result = sftp.stat(file)

                if S_ISDIR(stat_result.st_mode):
                    self.pullDir(sftp, file, destination)
                else:
                    self.pullFile(sftp, file, destination)
        except IOError as e:
            print("Couldn't download file from device: {0}".format(e))
            return 1
        finally:
            sftp.close()

        return 0
