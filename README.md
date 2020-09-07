## vimedia                                                                           
Control your media players from inside Vim, if you're really
that lazy 😏

## Usage
- `:Play`         => Begin playback from active media player
- `:Pause`        => Pause playback from active media player
- `:PauseAll`     => Pause playback from all runing media players
- `:Skip`         => Skip to next song
- `:Prev`         => Go back to previous song
- `:Restart`      => Replay current song from the beginning
- `:Shuffle`      => Toggle shuffle for the media player
- `:Mute`         => Mute audio for all media players
- `:Unmute`       => Unmute audio for all media players
- `:Vol`          => Toggle volume louder/quieter
- `:Quit`         => Send quit signal to active media player
- `:ActivePlayer` => Confirm active media player
- `:SelectPlayer` => Select/change active media player from list of all running options

Please keep in mind that some media players may not have implemented MPRIS
fully/at all and available functionality can vary with each player. At some point
I will go through and properly add debug messages where functionality is not supported, 
but for now I've just addressed those places that throw errors.

Throw an env like the following in your .zshrc/.bashrc to configure your preferred default player:

`export DEFAULT_VIMEDIA_PLAYER=chromium`

If you're unsure of the name to set here, try opening the media player and 
running `:SelectPlayer` from within Vim to get a list of options.

## Coming soon
- Seek forward/backwards
- Optional status bar

Suggestions/contributions welcome.

## Installation
Using your preferred plugin manager or if all else fails:

`git clone https://github.com/alyosha/vimedia ~/.vim/bundle/vimedia`

You may need to install a newer version of Vim if yours wasn't built with python3.

