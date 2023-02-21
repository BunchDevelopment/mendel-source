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
import platform
import queue
import select
import socket
import sys
import threading


TYPE_KEYBOARD_INPUT = 0
TYPE_TERMINAL_OUTPUT = 1
TYPE_REMOTE_CLOSED = 2
TYPE_SOCKET_TIMEOUT = 3
TYPE_EXIT_CODE = 4
KEEP_ALIVE_SECONDS = 10


class ConnectionClosedError(Exception):
    def __init__(self, exit_code=None):
        self.exit_code = exit_code


class SocketTimeoutError(Exception):
    pass


class UnknownEventTypeError(Exception):
    pass


def GetTtyWindowSize(fd):
    import fcntl
    import struct
    import termios
    tty_size = fcntl.ioctl(fd, termios.TIOCGWINSZ, '....')
    return struct.unpack('hh', tty_size)


class PosixConsole:
    def __init__(self, channel, inputfile):
        self.channel = channel
        self.inputfile = inputfile
        self.has_tty = False
        self.uname = os.uname().sysname

    def _updateWindowSize(self, signum, stackFrame):
        if self.has_tty:
            (rows, columns) = GetTtyWindowSize(self.inputfile)
            self.channel.resize_pty(columns, rows, 0, 0)

    def _socketSendQueueLevel(self):
        import fcntl
        import socket
        import struct

        SIOCOUTQ = 0x5411
        SO_NWRITE = 0x1024
        sock = self.channel.get_transport().sock

        # Only Linux doesn't support SO_NWRITE, which has been available since 4.3 BSD. O.o
        if self.uname == "Linux":
            return struct.unpack("I", fcntl.ioctl(sock.fileno(), SIOCOUTQ, '\0\0\0\0'))[0]

        return sock.getsockopt(socket.SOL_SOCKET, SO_NWRITE)


    def run(self):
        import termios
        import tty
        import signal

        from termios import ISTRIP, INLCR, IGNCR, ICRNL, IXON, IXANY, IXOFF
        from termios import ISIG, ICANON, ECHO, ECHOE, ECHOK, ECHONL
        from termios import OPOST, VMIN, VTIME
        from termios import TCSADRAIN

        has_tty = False
        old_tty_attrs = None
        escape_level = 0

        try:
            old_tty_attrs = termios.tcgetattr(self.inputfile)

            (iflag, oflag, cflag, lflag, ispeed, ospeed, cc) = old_tty_attrs
            iflag &= ~(ISTRIP | INLCR | IGNCR | ICRNL | IXON | IXANY | IXOFF)
            lflag &= ~(ISIG | ICANON | ECHO | ECHOE | ECHOK | ECHONL)
            oflag &= ~OPOST
            cc[VMIN] = 1
            cc[VTIME] = 0

            newattrs = [iflag, oflag, cflag, lflag, ispeed, ospeed, cc]
            termios.tcsetattr(self.inputfile, TCSADRAIN, newattrs)

            signal.signal(signal.SIGWINCH, self._updateWindowSize)

            self.has_tty = True

        except termios.error as e:
            self.has_tty = False

        try:
            self.channel.settimeout(0)
            self.channel.get_transport().set_keepalive(KEEP_ALIVE_SECONDS)
            timeout_count = 0
            initial_tx_level = 0

            while True:
                read, write, exception = select.select([self.channel,
                                                        self.inputfile],
                                                       [], [], KEEP_ALIVE_SECONDS + 1)

                select_timedout = not read and not write and not exception
                if select_timedout:
                    timeout_count += 1

                    if timeout_count == 1:
                        initial_tx_level = self._socketSendQueueLevel()
                    else:
                        current_tx_level = self._socketSendQueueLevel()
                        if current_tx_level and current_tx_level >= initial_tx_level:
                            raise SocketTimeoutError(socket.timeout())
                else:
                    timeout_count = 0

                # data from device to host
                if self.channel in read:
                    try:
                        data = self.channel.recv(256)
                        if not data:
                            exit_code = None
                            if self.channel.exit_status_ready():
                                exit_code = self.channel.recv_exit_status()
                            raise ConnectionClosedError(exit_code=exit_code)
                        sys.stdout.write(data.decode("utf-8", errors="ignore"))
                        sys.stdout.flush()
                    except socket.timeout as e:
                        raise SocketTimeoutError(e)

                # data from host to device
                if self.inputfile in read:
                    fd = self.inputfile.fileno()
                    data = os.read(fd, 1)

                    if escape_level == 0 and data == b'\r':
                        escape_level += 1
                    elif escape_level == 1 and data == b'~':
                        escape_level += 1
                        continue
                    elif escape_level == 2 and data == b'.':
                        raise ConnectionClosedError(exit_code=0)
                    else:
                        escape_level = 0

                    if not data:
                        exit_code = None
                        if self.channel.exit_status_ready():
                            exit_code = self.channel.recv_exit_status()
                        raise ConnectionClosedError(exit_code=exit_code)

                    self.channel.send(data)
        finally:
            if self.has_tty:
                termios.tcsetattr(self.inputfile, TCSADRAIN, old_tty_attrs)


class KeyboardInputThread(threading.Thread):
    def __init__(self, queue):
        super(KeyboardInputThread, self).__init__()
        self.daemon = True
        self.queue = queue

    def run(self):
        import msvcrt

        while True:
            ch = msvcrt.getch()
            self.queue.put((TYPE_KEYBOARD_INPUT, ch))


class TerminalOutputThread(threading.Thread):
    def __init__(self, queue, channel):
        super(TerminalOutputThread, self).__init__()
        self.daemon = True
        self.queue = queue
        self.channel = channel

    def run(self):
        while True:
            try:
                data = self.channel.recv(256)
                if not data:
                    exit_code = None
                    if self.channel.exit_status_ready():
                        exit_code = self.channel.recv_exit_status()
                    self.queue.put((TYPE_REMOTE_CLOSED, exit_code))
                    break
                data = data.decode("utf-8", errors="ignore")
                self.queue.put((TYPE_TERMINAL_OUTPUT, data))
            except socket.timeout:
                self.queue.put((TYPE_SOCKET_TIMEOUT, None))
                break

        exit_status = self.channel.recv_exit_status()
        self.queue.put((TYPE_EXIT_CODE, exit_status))


class WindowsConsole:
    def __init__(self, channel, inputfile):
        self.channel = channel
        self.dataQueue = queue.Queue()
        self.inputThread = KeyboardInputThread(self.dataQueue)
        self.outputThread = TerminalOutputThread(self.dataQueue, self.channel)

    def run(self):
        self.inputThread.start()
        self.outputThread.start()

        escape_level = 0

        while True:
            dataType, data = self.dataQueue.get()

            if dataType == TYPE_KEYBOARD_INPUT:
                if escape_level == 0 and data == b'\r':
                    escape_level += 1
                elif escape_level == 1 and data == b'~':
                    escape_level += 1
                    continue
                elif escape_level == 2 and data == b'.':
                    raise ConnectionClosedError(exit_code=0)
                else:
                    escape_level = 0

                self.channel.send(data.decode("utf-8", errors="ignore"))
            elif dataType == TYPE_TERMINAL_OUTPUT:
                sys.stdout.write(data)
                sys.stdout.flush()
            elif dataType == TYPE_REMOTE_CLOSED:
                raise ConnectionClosedError(exit_code=data)
            elif dataType == TYPE_SOCKET_TIMEOUT:
                raise SocketTimeoutError()
            else:
                raise UnknownEventTypeError()


class Console:
    def __init__(self, channel, inputfile):
        if os.name == 'nt':
            self._console = WindowsConsole(channel, inputfile)
        else:
            self._console = PosixConsole(channel, inputfile)

    def run(self):
        return self._console.run()
