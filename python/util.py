import dbus

MPRIS_PREFIX = "org.mpris.MediaPlayer2."
CHROMIUM_PATTERN = "chromium"


def get_active_player_names():
    names = dbus.SessionBus(private=True).list_names()
    return list(filter(lambda name: name.startswith(MPRIS_PREFIX), names))


def get_selected_player_name(selected_player_suffix):
    if selected_player_suffix == "":
        return ""

    for active_player_name in get_active_player_names():
        if selected_player_suffix in active_player_name:
            return active_player_name

    return ""


def normalize_player_name(dbus_name):
    name = str(dbus_name).replace(MPRIS_PREFIX, "", 1)

    if CHROMIUM_PATTERN in name:
        return CHROMIUM_PATTERN

    return name


def to_vim_string(val):
    return '\"' + val + '\"'
