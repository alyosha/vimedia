## vimedia                                                                             
vimedia lets you control your media players from inside vim. You know, if you're really
that lazy... 

## Commands
- `:Play`         => Begin playback from active media player
- `:Pause`        => Pause playback from active media player
- `:PauseAll`     => Pause playback from all runing media players
- `:Skip`         => Skip to next song
- `:Prev`         => Go back to previous song
- `:Restart`      => Replay current song from the beginning
- `:Mute`         => Mute audio for all media players
- `:Unmute`       => Unmute audio for all media players
- `:Quit`         => Send quit signal to active media player
- `:ActivePlayer` => Confirm active media player
- `:ChangePlayer` => Select active media player from list of all running/supported options

Please keep in mind that some media players have not fully implemented MPRIS
yet and not all functionality may work with every player.

## Coming soon
- Seek forward/backwards
- Volume toggle
- Shuffle
- Optional status bar
