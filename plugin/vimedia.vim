if !has("python3")
    echom "only supported for vim versions built with python3"
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

" *************************************************************************** "
" ***************************   Command Bindngs   *************************** " 
" *************************************************************************** "

command! -nargs=0 Play call s:play()
command! -nargs=0 Pause call s:pause(0)
command! -nargs=0 PauseAll call s:pause(1)
command! -nargs=0 Skip call s:skip()
command! -nargs=0 Prev call s:previous()
command! -nargs=0 Restart call s:restart()
command! -nargs=0 Mute call s:mute()
command! -nargs=0 Unmute call s:unmute()
command! -nargs=0 Quit call s:quit()
command! -nargs=0 ActivePlayer call s:active_player()
command! -nargs=0 ChangePlayer call s:present_player_options()

" *************************************************************************** "
" ****************************   Functionality   **************************** " 
" *************************************************************************** "

fu! s:play()
  if s:selected_player_suffix == ""
      echom "Please select a media player"
  else
      python3 vmd.pause_all(True)
      python3 vmd.selected_player.play()
  endif
endfu

fu! s:pause(all_players)
  if s:selected_player_suffix == ""
      echom "Please select a media player"
  elseif a:all_players
      python3 vmd.pause_all(False)
   else
      python3 vmd.selected_player.pause()
  endif
endfu

fu! s:skip()
  if s:selected_player_suffix == ""
      return
  endif
  python3 vmd.selected_player.next()
endfu

fu! s:previous()
  if s:selected_player_suffix == ""
      return
  endif
  python3 vmd.selected_player.previous()
endfu

fu! s:restart()
  if s:selected_player_suffix == ""
      return
  endif
  python3 vmd.selected_player.restart()
endfu

fu! s:active_player()
  if s:selected_player_suffix != ""
      echom s:selected_player_suffix
  else
      echom "No media player configured"
  endif
endfu

fu! s:present_player_options() abort
    vnew | exe 'vert resize '.(&columns/4)
    setl bh=wipe bt=nofile nobl noswf nowrap

    python3 util.update_player_options()

    sil! 0put = s:active_player_names
    sil! $d_
    setl noma ro

    nno <silent> <buffer> <nowait> q     :<c-u>close<cr>
    nno <silent> <buffer> <nowait> <cr>  :<c-u>call <sid>set_selected_player()<cr>
endfu

fu! s:set_selected_player() abort
    let s:selected_player_suffix = expand("<cword>") 
    python3 vmd = vimedia.Vimedia()
    echom "Updated active player" 
    close
endfu

fu! s:mute() 
  python3 vmd.adjust_volume_all(0.0)
endfu

fu! s:unmute() 
  python3 vmd.adjust_volume_all(1.0)
endfu

fu! s:quit()
  python3 vmd.base.quit()
endfu

let g:vimedia_plugin_loaded = 1
