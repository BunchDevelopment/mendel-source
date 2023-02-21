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


CONFIG_BASEDIR = os.path.join(os.path.expanduser("~"), ".config", "mdt")
CONFIG_ATTRDIR = os.path.join(CONFIG_BASEDIR, "attribs")

DEFAULT_USERNAME = "mendel"
DEFAULT_PASSWORD = "mendel"
DEFAULT_DISABLE_PASSWD_AUTH = "true"
DEFAULT_ENV_WHITELIST = "TERM LANG LC_*"


class Config:
    def __init__(self):
        self.ensureConfigDirExists()

    def ensureConfigDirExists(self):
        if not os.path.exists(CONFIG_BASEDIR):
            os.makedirs(CONFIG_BASEDIR, mode=0o700)
        if not os.path.exists(CONFIG_ATTRDIR):
            os.makedirs(CONFIG_ATTRDIR, mode=0o700)

    def getAllAttributes(self):
        vars = {}
        for name in os.listdir(CONFIG_ATTRDIR):
            vars[name] = self.getAttribute(name)
        return vars

    def getAttribute(self, name, default=None):
        path = os.path.join(CONFIG_ATTRDIR, name)
        if os.path.exists(path):
            with open(path, "r") as fp:
                return fp.readline().rstrip()

        return default

    def setAttribute(self, name, value):
        path = os.path.join(CONFIG_ATTRDIR, name)
        with open(path, "w") as fp:
            fp.write(value + "\n")

    def clearAttribute(self, name):
        path = os.path.join(CONFIG_ATTRDIR, name)
        if os.path.exists(path):
            os.unlink(path)

    def preferredDevice(self, devicename=None):
        if not devicename:
            return self.getAttribute("preferred-device")
        self.setAttribute("preferred-device", devicename)

    def username(self, username=None):
        if not username:
            return self.getAttribute("username", DEFAULT_USERNAME)
        self.setAttribute("username", username)

    def password(self, password=None):
        if not password:
            return self.getAttribute("password", DEFAULT_PASSWORD)
        self.setAttribute("password", password)

    def envWhitelist(self, whitelist=None):
        if not whitelist:
            return self.getAttribute("env-whitelist", DEFAULT_ENV_WHITELIST)
        self.setAttribute("env-whitelist", whitelist)

    def shouldDisablePasswordAuth(self, disablePasswdAuth=None):
        if disablePasswdAuth == None:
            return self.getAttribute("disable-password-auth",
                                     DEFAULT_DISABLE_PASSWD_AUTH)
        self.setAttribute("disable-password-auth", disablePasswdAuth)


class GetCommand:
    '''Usage: mdt get [<variablename>]

Returns the value currently set for a given variable name. Some useful
nvariables are:

    preferred-device    - set this to your preferred device name to default
                          most commands to manipulating this specific device.
                          This can be set to an IPv4 address to bypass the mDNS
                          lookup.
    username            - set this to the username that should be used to
                          connect to a device with. Defaults to 'mendel'.
    password            - set this to the password to use to login to a new
                          device with. Defaults to 'mendel'. Only used
                          during the initial setup phase of pushing an SSH
                          key to the board.

If no variable name is provided, 'mdt get' will print out the list of all
known stored variables and their values. Note: default values are not printed.
'''

    def __init__(self):
        self.config = Config()

    def run(self, args):
        if len(args) == 2:
            value = self.config.getAttribute(args[1])
            if value == None:
                print("{0} is unset".format(args[1]))
            else:
                print("{0} is {1}".format(args[1],
                                    self.config.getAttribute(args[1])))
        else:
            vars = self.config.getAllAttributes()
            if not vars:
                print("No variables are set.")
                return True

            for name, value in vars.items():
                print("{0} is {1}".format(name, value))
            return True


class SetCommand:
    '''Usage: mdt set <variablename> <value>

Sets the value for a given variable name. Some useful variables are:

    preferred-device    - set this to your preferred device name to default
                          most commands to manipulating this specific device.
                          This can be set to an IPv4 address to bypass the mDNS
                          lookup.
    username            - set this to the username that should be used to
                          connect to a device with. Defaults to 'mendel'.
    password            - set this to the password to use to login to a new
                          device with. Defaults to 'mendel'. Only used
                          during the initial setup phase of pushing an SSH
                          key to the board.

Note that setting a variable to the empty string does not clear it back to
the default value! Use 'mdt clear' for that.
'''
    def __init__(self):
        self.config = Config()

    def run(self, args):
        if len(args) != 3:
            print("Usage: mdt set <variablename> <value>")
            return 1

        self.config.setAttribute(args[1], args[2])
        print("Set {0} to {1}".format(args[1], args[2]))


class ClearCommand:
    '''Usage: mdt clear <variablename>

Clears the value for a given variable name, resetting it back to its
default value.
'''
    def __init__(self):
        self.config = Config()

    def run(self, args):
        if args:
            self.config.clearAttribute(args[1])
            print("Cleared {0}".format(args[1]))
