from mpris import Mpris
from util import to_vim_string
from time import sleep
import vim
import dbus
import sys


class Player(Mpris):

    INTERFACE_NAME = "org.mpris.MediaPlayer2.Player"

    def __init__(self, name):
        super().__init__(name)

    def refresh_now_playing(self):
        title = self.get_title()
        artist = self.get_artist()
        pos = self.get_position()

        if title == "" or artist == "" or pos == 0:
            return

        vim.command('let s:current_track_name = ' + to_vim_string(title))
        vim.command('let s:current_artist_name = ' + to_vim_string(artist))
        vim.command('let s:ticker_microseconds = ' + str(pos))

    def play(self):
        try:
            self.iface.Play()
        except dbus.exceptions.DBusException:
            print("Must start first song from media player to set the play source")

    def pause(self):
        self.iface.Pause()

    def next(self):
        try:
            self.iface.Next()
        except:
            return

    def previous(self):
        start_track = self.get_title()
        try:
            self.iface.Previous()
        except:
            return
        sleep(0.5)  # Need to sleep a bit to ensure new metadata has arrived.
        if self.get_title() == start_track:
            try:
                self.iface.Previous()
            except:
                return

    def restart(self):
        start_track = self.get_title()
        self.iface.Previous()
        sleep(0.5)  # Need to sleep a bit or the Next call will be ignored.
        if self.get_title() == start_track:
            return
        self.iface.Next()

    def set_volume(self, value):
        self.set_property('Volume', value)

    def adjust_volume(self, value):
        previous_volume = self.get_property('Volume')
        self.set_property('Volume', previous_volume + value)

        # If these are equal, volume must not be configurable for the player.
        if self.get_property('Volume') != previous_volume:
            vim.command('let s:previous_volume = ' + str(previous_volume))

    def shuffle(self):
        try:
            previous_status = self.get_property('Shuffle')
            self.set_property('Shuffle', not previous_status)
            print("Shuffle status: " + ("on" if previous_status == 0 else "off"))
        except:
            print(self.name + " has not implemented Shuffle yet")

    def get_artist(self):
        metadata = self.get_metadata()

        if metadata != None:
            try:
                artist = metadata["xesam:artist"][0]
            except:
                return ""

            return str(artist)

    def get_title(self):
        metadata = self.get_metadata()

        if metadata != None:
            try:
                title = metadata["xesam:title"]
            except:
                return ""

            return str(title)

    def get_position(self):
        try:
            return int(self.get_property('Position'))
        except:
            return 0

    def get_metadata(self):
        try:
            return self.get_property('Metadata')
        except:
            return None
