from util import normalize_player_name
import dbus


class Mpris():

    def __init__(self, name):
        self.system_name = name
        self.name = normalize_player_name(name)
        self.bus = dbus.SessionBus(private=True)
        self.dbus_object = self.bus.get_object(name, "/org/mpris/MediaPlayer2")
        self.iface = dbus.Interface(self.dbus_object, self.INTERFACE_NAME)
        self.properties = dbus.Interface(
            self.dbus_object,
            "org.freedesktop.DBus.Properties",
        )

    def get_property(self, prop_name):
        return self.properties.Get(self.INTERFACE_NAME, prop_name)

    def set_property(self, prop_name, value):
        return self.properties.Set(self.INTERFACE_NAME, prop_name, value)
