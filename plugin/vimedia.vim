if !has("python3")
  echom "vimedia only supported for vim versions built with python3"
  finish
endif

if exists('g:vimedia_plugin_loaded')
  finish
endif

set timeout timeoutlen=1000 ttimeoutlen=0

if !exists('g:vimedia_statusline_enabled')
  let g:vimedia_statusline_enabled = 1
endif

let s:plugin_root_dir = fnamemodify(resolve(expand('<sfile>:p:h')), ':h')

" *************************************************************************** "
" ***************************   D-Bus Commands   **************************** "
" *************************************************************************** "

fu! s:GetActivePlayersCmd()
  return s:plugin_root_dir . '/dbus/get_active_players'
endfu

fu! s:GetArtistCmd(player)
  return s:plugin_root_dir . '/dbus/get_metadata ' . a:player . " Artist"
endfu

fu! s:GetTitleCmd(player)
  return s:plugin_root_dir . '/dbus/get_metadata ' . a:player . " Title"
endfu

fu! s:GetPositionCmd(player)
  return s:plugin_root_dir . '/dbus/get_property ' . a:player . ' Position'
endfu 

fu! s:GetShuffleCmd(player)
  return s:plugin_root_dir . '/dbus/get_property ' . a:player . ' Shuffle'
endfu

fu! s:GetVolumeCmd(player)
  return s:plugin_root_dir . '/dbus/get_property ' . a:player . ' Volume'
endfu

fu! s:SetVolumeCmd(player, volume)
  return s:plugin_root_dir . '/dbus/set_property ' . a:player . ' Volume double ' . string(a:volume)
endfu

fu! s:SetShuffleCmd(player, shuffle_status)
  return s:plugin_root_dir . '/dbus/set_property ' . a:player . ' Shuffle boolean ' . a:shuffle_status
endfu

fu! s:PlayCmd(player)
  return s:plugin_root_dir . '/dbus/control_playback ' . a:player . ' Play'
endfu

fu! s:PauseCmd(player)
  return s:plugin_root_dir . '/dbus/control_playback ' . a:player . ' Pause'
endfu

fu! s:NextCmd(player)
  return s:plugin_root_dir . '/dbus/control_playback ' . a:player . ' Next'
endfu

fu! s:PreviousCmd(player)
  return s:plugin_root_dir . '/dbus/control_playback ' . a:player . ' Previous'
endfu

fu! s:SeekCmd(player, duration)
  return s:plugin_root_dir . '/dbus/seek ' . a:player . ' ' . a:duration
endfu

fu! s:QuitCmd(player)
  return s:plugin_root_dir . '/dbus/quit ' . a:player
endfu

" *************************************************************************** "
" **********************   D-Bus Command Callbacks   ************************ "
" *************************************************************************** "

fu! s:SetPlayerCallback(channel, msg)
  for player in split(a:msg, ",")
    if stridx(player, s:selected_player_abbrev) != -1
      let s:selected_player = player
    endif
  endfor
endfu

fu! s:GetPositionCallback(channel, msg)
  if a:msg == "0"
    return
  endif
  let s:ticker_microseconds = a:msg
endfu

fu! s:GetTitleCallback(channel, msg)
  if a:msg == ""
    return
  endif
  let s:current_track_name = a:msg
endfu

fu! s:GetArtistCallback(channel, msg)
  if a:msg == ""
    return
  endif
  let s:current_artist_name = a:msg
endfu

fu! s:PlayCallback(channel, msg)
  call s:PauseAllPlayers(a:msg)
  sleep 5m
  call job_start(s:PlayCmd(s:selected_player))
endfu

fu! s:PauseAllCallback(channel, msg)
  call s:PauseAllPlayers(a:msg)
endfu

fu! s:MuteCallback(channel, msg)
  call s:SetVolumeAll(a:msg, 0.0)
endfu

fu! s:UnmuteCallback(channel, msg)
  call s:SetVolumeAll(a:msg, s:previous_volume)
endfu

fu! s:ShuffleCallback(channel, msg)
  if a:msg == "false"
    call job_start(s:SetShuffleCmd(s:selected_player, "true"))
    echom "Shuffle status: on"
  elseif a:msg == "true"
    call job_start(s:SetShuffleCmd(s:selected_player, "false"))
    echom "Shuffle status: off"
  endif
endfu

fu! s:SelectPlayerCallback(channel, msg)
  let s:abbreviated_names = []
  for player in split(a:msg, ",")
    let l:abbreviated_name = substitute(player, "org.mpris.MediaPlayer2.", "", "")
    if stridx(l:abbreviated_name, "chromium") != -1
      call add(s:abbreviated_names, "chromium")
    else
      call add(s:abbreviated_names, l:abbreviated_name)
    endif
  endfor
  let s:active_player_names = s:abbreviated_names
  call s:PresentOptions(s:interaction_type_select_player)
endfu

fu! s:QuitCallback(channel, msg)
  call s:init_player_config()
  set statusline=
endfu

" *************************************************************************** "
" **************************   Timer Functions   **************************** "
" *************************************************************************** "

fu! s:init_now_playing_config()
  let s:current_track_name = "N/A"
  let s:current_artist_name = "N/A"
  let s:ticker_microseconds = 0
endfu

call s:init_now_playing_config()

fu! s:Refresh(timer)
  if s:selected_player == "N/A"
    return
  endif

  call job_start(s:GetPositionCmd(s:selected_player), {"out_cb": function("s:GetPositionCallback")})
  call job_start(s:GetTitleCmd(s:selected_player), {"out_cb": function("s:GetTitleCallback")})
  call job_start(s:GetArtistCmd(s:selected_player), {"out_cb": function("s:GetArtistCallback")})
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
  if g:vimedia_statusline_enabled == 0
    return
  endif

  if s:selected_player == "N/A" || s:current_artist_name == "N/A" || s:current_track_name == "N/A"
    return
  endif

  set statusline=
  set statusline+=\%{NowPlayingText()}
  set statusline+=%=
  set statusline+=\%{PlaybackTicker()}
endfu

"" Refresh track/artist name and playback ticker every half-second
let timer = timer_start(500, function('s:Refresh'), {'repeat':-1})
"" Update the status line each second with the latest playback info 
let timer = timer_start(1000, function('s:UpdateStatusline'), {'repeat':-1})

" *************************************************************************** "
" *************************   Base Functionality   ************************** "
" *************************************************************************** "

fu! s:init_player_config()
  let s:selected_player_abbrev = ""

  if exists('g:vimedia_default_player')
    let s:selected_player_abbrev = g:vimedia_default_player
  endif

  let s:selected_player = "N/A"

  call job_start(s:GetActivePlayersCmd(), {"out_cb": function("s:SetPlayerCallback")})
endfu

call s:init_player_config()

let s:interaction_type_select_player = "select_player_interaction"
let s:interaction_type_toggle_volume = "toggle_volume_interaction"

let s:previous_volume = 1.0

let s:toggle_volume_opt_up = "Louder"
let s:toggle_volume_opt_down = "Quieter"
let s:toggle_volume_opt_done = "Done"
 
let s:toggle_volume_options = [s:toggle_volume_opt_up, s:toggle_volume_opt_down, s:toggle_volume_opt_done]

fu! s:PauseAllPlayers(players_str)
  for player in split(a:players_str, ",")
    call job_start(s:PauseCmd(player))
  endfor
endfu

fu! s:Play() abort
  call job_start(s:GetActivePlayersCmd(), {"out_cb": function("s:PlayCallback")})
endfu

fu! s:Pause() abort
  call job_start(s:PauseCmd(s:selected_player))
endfu

fu! s:PauseAll() abort
  call job_start(s:GetActivePlayersCmd(), {"out_cb": function("s:PauseAllCallback")})
endfu

fu! s:Skip() abort
  call job_start(s:NextCmd(s:selected_player))
endfu

fu! s:Previous() abort
  call job_start(s:PreviousCmd(s:selected_player))
endfu

fu! s:Seek(duration_seconds) abort
  let l:duration_microseconds = a:duration_seconds * 1000000
  call job_start(s:SeekCmd(s:selected_player, l:duration_microseconds))
endfu

fu! s:Shuffle() abort
  call job_start(s:GetShuffleCmd(s:selected_player), {"out_cb": function("s:ShuffleCallback")})
endfu

fu! s:ActivePlayer() abort
  if s:selected_player_abbrev != ""
    echom s:selected_player != "N/A" ? s:selected_player_abbrev : s:selected_player_abbrev . " selected but not active"
  else
    echom "No media player configured"
  endif
endfu

fu! s:SetVolumeAll(players_str, volume) abort
  for player in split(a:players_str, ",")
    call job_start(s:SetVolumeCmd(s:selected_player, a:volume))
  endfor
endfu

fu! s:ToggleVolume() abort
  let l:selected_opt = expand("<cword>") 
  if l:selected_opt == s:toggle_volume_opt_up
    let l:next_volume = s:previous_volume + 0.1
    let s:previous_volume = l:next_volume
    call job_start(s:SetVolumeCmd(s:selected_player, l:next_volume))
  elseif l:selected_opt == s:toggle_volume_opt_down
    let l:next_volume = s:previous_volume - 0.1
    let s:previous_volume = l:next_volume
    call job_start(s:SetVolumeCmd(s:selected_player, l:next_volume))
  elseif l:selected_opt == s:toggle_volume_opt_done
    close
  endif
endfu

fu! s:AdjustVolume() abort
  call s:PresentOptions(s:interaction_type_toggle_volume)
endfu

fu! s:Mute() abort
 call job_start(s:GetActivePlayersCmd(), {"out_cb": function("s:MuteCallback")})
endfu

fu! s:Unmute() abort
 call job_start(s:GetActivePlayersCmd(), {"out_cb": function("s:UnmuteCallback")})
endfu

fu! s:Quit() abort
  call job_start(s:QuitCmd(s:selected_player), {"out_cb": function("s:QuitCallback")})
endfu

fu! s:PresentOptions(interaction_type) abort
  vnew | exe 'vert resize '.(&columns/4)
  setl bh=wipe bt=nofile nobl noswf nowrap

  if a:interaction_type == s:interaction_type_select_player
    sil! 0put = s:active_player_names
    nno <silent> <buffer> <nowait> <cr>  :<c-u>call<sid>SetSelectedPlayer()<cr>
  elseif a:interaction_type == s:interaction_type_toggle_volume
    sil! 0put = s:toggle_volume_options
    nno <silent> <buffer> <nowait> <cr>  :<c-u>call<sid>ToggleVolume()<cr>
  endif

  sil! $d_
  setl noma ro
  nno <silent> <buffer> <nowait> q :<c-u>close<cr>
endfu

fu! s:SetSelectedPlayer() abort
  let s:selected_player_abbrev = expand("<cword>") 
  call job_start(s:GetActivePlayersCmd(), {"out_cb": function("s:SetPlayerCallback")})
  call s:init_now_playing_config()
  set statusline=
  echom "Updated active player" 
  close
endfu

fu! s:CheckPlayer(fn, ...) abort
  if s:selected_player == "N/A"
    echom "Please select an active media player"
    return
  endif

  if a:0 == 1
    call a:fn(a:1)
  else
    call a:fn()
  endif
endfu

" *************************************************************************** "
" ***************************   Command Bindngs   *************************** " 
" *************************************************************************** "

"" Require selected media player
com! -nargs=0 Play call s:CheckPlayer(function("s:Play"))
com! -nargs=0 Pause call s:CheckPlayer(function("s:Pause"))
com! -nargs=0 Skip call s:CheckPlayer(function("s:Skip"))
com! -nargs=0 Prev call s:CheckPlayer(function("s:Previous"))
com! -nargs=1 Seek call s:CheckPlayer(function("s:Seek"), <args>)
com! -nargs=0 Restart call s:CheckPlayer(function("s:Restart"))
com! -nargs=0 Shuffle call s:CheckPlayer(function("s:Shuffle"))
com! -nargs=0 Vol call s:CheckPlayer(function("s:AdjustVolume"))
com! -nargs=0 Quit call s:CheckPlayer(function("s:Quit"))

"" Do not require selected media player
com! -nargs=0 PauseAll call s:PauseAll()
com! -nargs=0 Mute call s:Mute()
com! -nargs=0 Unmute call s:Unmute() 
com! -nargs=0 SelectPlayer call job_start(s:GetActivePlayersCmd(), {"out_cb": function("s:SelectPlayerCallback")})
com! -nargs=0 ActivePlayer call s:ActivePlayer()

let g:vimedia_plugin_loaded = 1
