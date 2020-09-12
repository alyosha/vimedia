if !has("python3")
    echom "vimedia only supported for vim versions built with python3"
    finish
endif

if exists('g:vimedia_plugin_loaded')
    finish
endif

"" Point to location of python code
let s:plugin_root_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')

fu! s:init_player_config()
  let s:selected_player_suffix = $DEFAULT_VIMEDIA_PLAYER
  let s:selected_player_configured = 0
endfu

call s:init_player_config()

python3 << EOF
import sys
import vim
from os.path import normpath, join

plugin_root_dir = vim.eval('s:plugin_root_dir')
python_root_dir = normpath(join(plugin_root_dir, '..', 'python'))
sys.path.insert(0, python_root_dir)

import vimedia
import util
vmd = vimedia.Vimedia()
EOF

" *************************************************************************** "
" ***********************   Background Functions   ************************** "
" *************************************************************************** "

fu! s:init_now_playing_config()
  let s:current_track_name = "N/A"
  let s:current_artist_name = "N/A"
  let s:ticker_microseconds = 0
  let s:quit_in_progress = 0
endfu

call s:init_now_playing_config()

fu! GetPositionCallback(channel, msg)
  if a:msg == "0" || s:quit_in_progress == 1
    return
  endif
  let s:ticker_microseconds = a:msg
endfu

fu! GetTitleCallback(channel, msg)
  if a:msg == "" || s:quit_in_progress == 1
    return
  endif
  let s:current_track_name = a:msg
endfu

fu! GetArtistCallback(channel, msg)
  if a:msg == "" || s:quit_in_progress == 1
    return
  endif
  let s:current_artist_name = a:msg
endfu

fu! s:Refresh(timer)
  if s:selected_player_configured == 0
    return
  endif

  "" DBus system calls will block if not processed as jobs, so we
  "" update the now playing properties via async shell script execution.
  call job_start(s:plugin_root_dir . '/jobs/get_position ' . s:dest, {"out_cb": "GetPositionCallback"})
  call job_start(s:plugin_root_dir . '/jobs/get_title ' . s:dest, {"out_cb": "GetTitleCallback"})
  call job_start(s:plugin_root_dir . '/jobs/get_artist ' . s:dest, {"out_cb": "GetArtistCallback"})
endfu

fu! NowPlayingText()
  return s:current_track_name . " - " . s:current_artist_name
endfu

fu! PlaybackTicker()
  let l:pos_seconds = s:ticker_microseconds / 1000000
  let l:min = l:pos_seconds / 60
  let l:sec = l:pos_seconds - (l:min * 60)
  return l:min . ":" . (l:sec > 9 ? l:sec : ("0" . l:sec))
endfu

fu! s:UpdateStatusline(timer)
  if s:current_track_name == "N/A" || s:current_artist_name == "N/A"
    return
  endif

  set statusline=
  set statusline+=\%{NowPlayingText()}
  set statusline+=%=
  set statusline+=\%{PlaybackTicker()}
endfu

"" Refresh track/artist name and playback ticker every half-second (async)
let timer = timer_start(500, function('s:Refresh'), {'repeat':-1})

"" Update the status line each second with the latest playback info
let timer = timer_start(1000, function('s:UpdateStatusline'), {'repeat':-1})

" *************************************************************************** "
" *************************   Base Functionality   ************************** "
" *************************************************************************** "

let s:interaction_type_select_player = "select_player_interaction"
let s:interaction_type_toggle_volume = "toggle_volume_interaction"

let s:previous_volume = 1.0

let s:toggle_volume_opt_up = "Louder"
let s:toggle_volume_opt_down = "Quieter"
let s:toggle_volume_opt_done = "Done"
 
let s:toggle_volume_options = [s:toggle_volume_opt_up, s:toggle_volume_opt_down, s:toggle_volume_opt_done]

fu! s:Play() abort
  python3 vmd.pause_all(False)
  python3 vmd.selected_player.play()
endfu

fu! s:Pause() abort
  python3 vmd.selected_player.pause()
endfu

fu! s:PauseAll() abort
  python3 vmd.pause_all(False)
endfu

fu! s:Skip() abort
  python3 vmd.selected_player.next()
endfu

fu! s:Previous() abort
  python3 vmd.selected_player.previous()
endfu

fu! s:Restart() abort
  python3 vmd.selected_player.restart()
endfu

fu! s:Shuffle() abort
  python3 vmd.selected_player.shuffle()
endfu

fu! s:ActivePlayer() abort
  if s:selected_player_suffix != ""
    echom s:selected_player_configured == 1 ? s:selected_player_suffix : s:selected_player_suffix . " selected but not active"
  else
    echom "No media player configured"
  endif
endfu

fu! s:Mute() abort
  python3 vmd.set_volume_global(0.0)
endfu

fu! s:Unmute() abort
  python3 vmd.set_volume_global(vim.eval("s:previous_volume"))
endfu

fu! s:Quit() abort
  let s:quit_in_progress = 1
  python3 vmd.base.quit()
  call s:init_player_config()
  set statusline=
  let s:quit_in_progress = 0
endfu

fu! s:PresentOptions(interaction_type) abort
  vnew | exe 'vert resize '.(&columns/4)
  setl bh=wipe bt=nofile nobl noswf nowrap

  if a:interaction_type == s:interaction_type_select_player
    python3 vmd.update_player_options()
    sil! 0put = s:active_player_names
    nno <silent> <buffer> <nowait> <cr>  :<c-u>call<sid>SetSelectedPlayer()<cr>
  elseif a:interaction_type == s:interaction_type_toggle_volume
    sil! 0put = s:toggle_volume_options
    nno <silent> <buffer> <nowait> <cr>  :<c-u>call<sid>ToggleVolume()<cr>
  endif

  sil! $d_
  setl noma ro
  nno <silent> <buffer> <nowait> q     :<c-u>close<cr>
endfu

fu! s:SetSelectedPlayer() abort
  let s:selected_player_suffix = expand("<cword>") 
  python3 vmd = vimedia.Vimedia()
  call s:init_now_playing_config()
  set statusline=
  echom "Updated active player" 
  close
endfu

fu! s:ToggleVolume() abort
  let l:selected_opt = expand("<cword>") 
  if l:selected_opt == s:toggle_volume_opt_up
    python3 vmd.adjust_volume_global(0.1)
  elseif l:selected_opt == s:toggle_volume_opt_down
    python3 vmd.adjust_volume_global(-0.1)
  elseif l:selected_opt == s:toggle_volume_opt_done
    close
  endif
endfu

fu! s:CheckPlayer(fn, ...) abort
  if s:selected_player_configured == 0
    echom "Please select an active media player"
    return
  endif
  call a:fn()
endfu

" *************************************************************************** "
" ***************************   Command Bindngs   *************************** " 
" *************************************************************************** "

"" Require selected media player
com! -nargs=0 Play call s:CheckPlayer(function("s:Play"))
com! -nargs=0 Pause call s:CheckPlayer(function("s:Pause"))
com! -nargs=0 Skip call s:CheckPlayer(function("s:Skip"))
com! -nargs=0 Prev call s:CheckPlayer(function("s:Previous"))
com! -nargs=0 Restart call s:CheckPlayer(function("s:Restart"))
com! -nargs=0 Shuffle call s:CheckPlayer(function("s:Shuffle"))
com! -nargs=0 Quit call s:CheckPlayer(function("s:Quit"))

"" Do not require selected media player
com! -nargs=0 PauseAll call s:PauseAll()
com! -nargs=0 Mute call s:Mute()
com! -nargs=0 Unmute call s:Unmute()
com! -nargs=0 Vol call s:PresentOptions(s:interaction_type_toggle_volume)
com! -nargs=0 SelectPlayer call s:PresentOptions(s:interaction_type_select_player)
com! -nargs=0 ActivePlayer call s:ActivePlayer()

let g:vimedia_plugin_loaded = 1