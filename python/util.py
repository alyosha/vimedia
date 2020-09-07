import dbus
import vim
import re

MPRIS_PREFIX = "org.mpris.MediaPlayer2."
CHROMIUM_PATTERN = "chromium"


def get_active_player_names():
    names = dbus.SessionBus(private=True).list_names()
    return list(filter(lambda name: name.startswith(MPRIS_PREFIX), names))

def get_selected_player_name():
    selected_service_suffix = vim.eval('s:selected_player_suffix')

    if selected_service_suffix == "":
        return ""

    for active_service_name in get_active_player_names():
        if selected_service_suffix in active_service_name:
            return active_service_name

    return ""

def update_player_options():
    options = list(map(normalize_option, get_active_player_names()))
    vim.command('let s:active_player_names = ' + str(options))

def normalize_option(dbus_name):
    option = str(dbus_name).replace(MPRIS_PREFIX, "", 1)

    if CHROMIUM_PATTERN in option:
        return CHROMIUM_PATTERN

    return option
