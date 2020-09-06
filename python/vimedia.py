from player import Player
from base import Base
from util import get_selected_player_name, get_active_player_names
import vim
import dbus


class Vimedia():

    def __init__(self):
        selected_player_name = get_selected_player_name()

        if selected_player_name == "":
            return

        self.base = Base(selected_player_name)
        self.selected_player = Player(selected_player_name)

    def pause_all(self, exclude_selected):
        selected_player_name = get_selected_player_name()

        for player in list(map(Player,  get_active_player_names())):
            if player.name == selected_player_name and exclude_selected:
                continue
            player.pause()

    def adjust_volume_all(self, value):
        for player in list(map(Player,  get_active_player_names())):
            player.adjust_volume(dbus.Double(value))
