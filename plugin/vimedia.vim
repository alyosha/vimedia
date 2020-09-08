if !has("python3")
    echom "vimedia only supported for vim versions built with python3"
    finish
endif

if exists('g:vimedia_plugin_loaded')
    finish
endif

"" Point to location of python code
let s:plugin_root_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')

"" Set the users default media player if present
let s:selected_player_suffix = $DEFAULT_VIMEDIA_PLAYER

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

let s:interaction_type_select_player = "select_player_interaction"
let s:interaction_type_toggle_volume = "toggle_volume_interaction"

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
    echom s:selected_player_suffix
  else
    echom "No media player configured"
  endif
endfu

fu! s:Mute() abort
  python3 vmd.set_volume_global(0.0)
endfu

fu! s:Unmute() abort
  python3 vmd.set_volume_global(1.0)
endfu

fu! s:Quit() abort
  python3 vmd.base.quit()
  let s:selected_player_suffix = ""
endfu

fu! s:PresentOptions(interaction_type) abort
  vnew | exe 'vert resize '.(&columns/4)
  setl bh=wipe bt=nofile nobl noswf nowrap

  if a:interaction_type == s:interaction_type_select_player
    python3 util.update_player_options()
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
  if s:selected_player_suffix == ""
    echom "Please select a media player"
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