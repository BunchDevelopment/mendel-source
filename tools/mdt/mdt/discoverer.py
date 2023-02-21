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


from typing import cast
from zeroconf import ServiceBrowser, Zeroconf

import socket
import time


class DeviceNotFoundError(Exception):
    pass


class Discoverer:
    ANNOUNCE_PERIOD_SECS = 1
    MAXIMUM_WAIT_CYCLES = 10
    SERVICE_TYPE = "_googlemdt._tcp.local."

    def __init__(self, listener=None):
        self.discoveries = {}
        self.listener = listener
        self.zeroconf = None

    def discover(self):
        self.zeroconf = Zeroconf()
        self.browser = ServiceBrowser(self.zeroconf, Discoverer.SERVICE_TYPE, self)
        self._heard_announcement = True
        cycle_count = 0

        # Keep waiting until we stop hearing announcements for a full second, or until we've waited 10 seconds
        while self._heard_announcement and cycle_count < Discoverer.MAXIMUM_WAIT_CYCLES:
            cycle_count += 1
            self._heard_announcement = False
            time.sleep(Discoverer.ANNOUNCE_PERIOD_SECS)

        self.browser.cancel()
        self.browser = None
        self.zeroconf = None

    def add_service(self, zeroconf, type, name):
        info = self.zeroconf.get_service_info(type, name)

        if info:
            hostname = info.server.split('.')[0]
            address = info.parsed_addresses()[0]

            # Prevent duplicate announcements from extending the discovery delay
            if hostname not in self.discoveries:
                self._heard_announcement = True

            self.discoveries[hostname] = address

            if self.listener and hasattr(self.listener, "add_device"):
                self.listener.add_device(hostname, address)

    def remove_service(self, zeroconf, type, name):
        info = self.zeroconf.get_service_info(type, name)

        if info:
            if self.listener and hasattr(self.listener, "remove_device"):
                self.listener.remove_device(info.server,
                                            self.discoveries[info.server])

            if info.server in self.discoveries:
                self._heard_announcement = True
                del(self.discoveries[info.server])

    def update_service(self, zeroconf, type, name):
        """TODO(jtgans): Add this method once zeroconf figures out what it's for."""
        pass
