from mpris import Mpris
from time import sleep
import dbus


class Player(Mpris):

    INTERFACE_NAME = "org.mpris.MediaPlayer2.Player"

    def __init__(self, name):
        super().__init__(name)

    def play(self):
        self.iface.Play()

    def pause(self):
        self.iface.Pause()

    def next(self):
        self.iface.Next()

    def previous(self):
        start_track = self.get_title()
        self.iface.Previous()
        # Many players will simply restart the song if the position
        # is already past a certain point. We have a dedicated method
        # supporting restart, so make sure to actually go back here.
        sleep(0.5)  # Need to sleep a bit to ensure new metadata has arrived.
        if self.get_title() == start_track:
            self.iface.Previous()
            return

    def restart(self):
        start_track = self.get_title()
        # Not all implementations of MediaPlayer are perfect. Chromium
        # for example lacks trackid metadata, making Seek impossible.
        # For this reason we hack restart to prioritize universal support.
        self.iface.Previous()
        sleep(0.5)  # Need to sleep a bit or the Next call will be ignored.
        if self.get_title() == start_track:
            return
        self.iface.Next()

    def get_title(self):
        metadata = self.get_metadata()
        return str(metadata["xesam:title"])

    def get_metadata(self):
        return self.get_property('Metadata')

    def adjust_volume(self, value):
        self.set_property('Volume', value)
