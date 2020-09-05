from mpris import Mpris


class Base(Mpris):

    INTERFACE_NAME = "org.mpris.MediaPlayer2"

    def __init__(self, name):
        super().__init__(name)

    def quit(self):
        self.iface.Quit()
