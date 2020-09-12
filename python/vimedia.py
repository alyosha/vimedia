from player import Player
from base import Base
from util import get_selected_player_name, get_active_player_names, normalize_player_name, to_vim_string
import vim
import dbus


class Vimedia():

    def __init__(self):
        selected_player_name = get_selected_player_name(
            vim.eval('s:selected_player_suffix'))

        if selected_player_name == "":
            return

        self.base = Base(selected_player_name)
        self.selected_player = Player(selected_player_name)

        if self.selected_player:
            dest = to_vim_string(self.selected_player.system_name)
            vim.command('let s:selected_player_configured = ' + str(1))
            vim.command('let s:dest = ' + dest)

    def update_player_options(self):
        options = list(map(normalize_player_name, get_active_player_names()))
        vim.command('let s:active_player_names = ' + str(options))

    def pause_all(self, exclude_selected):
        selected_player_name = get_selected_player_name(
            vim.eval('s:selected_player_suffix'))

        for player in list(map(Player,  get_active_player_names())):
            if player.name == selected_player_name and exclude_selected:
                continue
            player.pause()

    def set_volume_global(self, value):
        for player in list(map(Player,  get_active_player_names())):
            player.set_volume(dbus.Double(value))

    def adjust_volume_global(self, value):
        for player in list(map(Player,  get_active_player_names())):
            player.adjust_volume(dbus.Double(value))
