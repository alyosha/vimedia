## vimedia                                                                           
Control your media players from inside Vim, if you're really
that lazy

![vimedia statusline](statusline.png)

In addition to displaying track/artist information in your statusline, you can also navigate 
through your media libraries, control volume, etc. using the following commands. Still slightly
experimental until all base functionality has been implemented.

## Usage
- `:Play`         => Begin playback from active media player
- `:Pause`        => Pause playback from active media player
- `:PauseAll`     => Pause playback from all running media players
- `:Skip`         => Skip to next song
- `:Prev`         => Go back to previous song
- `:Shuffle`      => Toggle shuffle for the media player
- `:Mute`         => Mute audio for all media players
- `:Unmute`       => Unmute audio for all media players
- `:Vol`          => Toggle volume louder/quieter
- `:Quit`         => Send quit signal to active media player
- `:ActivePlayer` => Confirm active media player
- `:SelectPlayer` => Select/change active media player from list of all running options

Please keep in mind that individual media players are responsible for implementing 
MPRIS properly/at all so available functionality can vary. At some point I will go 
through and properly add debug messages where functionality is not supported, but 
for now I've just tried to cover those places that throw errors when unavailable.

Throw an env like the following in your .zshrc/.bashrc to configure your preferred default player:

`export DEFAULT_VIMEDIA_PLAYER=chromium`

If you're unsure of the name to set here, try opening the media player and running `:SelectPlayer` 
from within Vim to get a list of options (remember the players need to be running/active to detect).

## Coming soon
- Seek forward/backwards
- Restart
- Hard previous (instead of just restarting when playback is past a certain point)
- Make status bar optional

Suggestions/contributions welcome.

## Installation
Using your preferred plugin manager or if all else fails:

`git clone https://github.com/alyosha/vimedia ~/.vim/bundle/vimedia`