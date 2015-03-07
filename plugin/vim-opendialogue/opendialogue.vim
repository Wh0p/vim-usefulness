" ================================================================================ 
" Copyright (C) 
" 2015 - Daniel Opitz
" This program is free software; you can redistribute it and/or
" modify it under the terms of the GNU General Public License
" as published by the Free Software Foundation; either version 2
" of the License, or (at your option) any later version.
" 
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
" 
" You should have received a copy of the GNU General Public License
" along with this program; if not, write to the Free Software
" Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
" ================================================================================  


if (exists('g:disable_vim_opendialogue'))
  finish
endif

if (v:version < 700)
  echoerr "Vim version ist < 7.0, which is totally fine with paraMark. But dude upgrade you vim...
endif



" ================================================== 
" GONFIG VARS
" ==================================================
if (!exists('g:vim_opendialogue_choose_file_filename'))
  let g:vim_opendialogue_choose_file_filename = '/tmp/vimopendialogue_choose_file.txt'
endif

if (!exists('g:vim_opendialogue_launch_terminal'))
  let g:vim_opendialogue_launch_terminal = 0
endif

if (!exists('g:vim_opendialogue_launch_terminal_name'))
  let g:vim_opendialogue_launch_terminal_name = 'gnome-terminal -x'
endif

if (!exists('g:vim_opendialogue_filemanager_command'))
  let g:vim_opendialogue_filemanager_command = 'ranger --choosefiles='
endif

if (!exists('g:vim_opendialogue_startup_directory_mode'))
  let g:vim_opendialogue_startup_directory_mode = "file"
endif

if (!exists('g:vim_opendialogue_default_open_mode_first'))
  let g:vim_opendialogue_default_open_mode_first = 'h'
endif

if (!exists(':vim_opendialogue_default_open_mode'))
  let g:vim_opendialogue_default_open_mode = 't'
endif







" Checks if mode is a valid openmode (mode in ['h', 'H', 't', 'T', 'v', 'V', 's', 'S', 'a', 'A'])
function! s:IsValidOpenMode(mode)
  if ((a:mode == 'h') || (a:mode == 't') || (a:mode == 'v') || (a:mode == 's') || (a:mode == 'a') || (a:mode == 'H') || (a:mode == 'T') || (a:mode == 'V') || (a:mode == 'S')|| (a:mode == 'A'))
    return 1
  else
    return 0
  endif
endfunction


" Checks if mode is a valid CAPITAL openmode (that indicates to be used for all upcoming files)
function! s:IsSkipOpenMode(mode)
  if ((a:mode == 'H') || (a:mode == 'T') || (a:mode == 'V') || (a:mode == 'A'))
    return 1
  else
    return 0
  endif
endfunction


" This function returns mode, if it is a valid openmode
" Otherwise returns the default open mode
function! s:ValidateOpenMode(mode, first)
  if s:IsValidOpenMode(a:mode) == 1
    return a:mode
  else
    if (a:first == 1)
      return g:vim_opendialogue_default_open_mode_first
    else
      return g:vim_opendialogue_default_open_mode
  endif
endfunction


" This function switches open modes and opens the file either in the current window, a new tab, a new vertical/horizontal split or aborts.
function! s:SwitchOpenFile(mode, name)
  " Switch how the file should be opened
  if ((a:mode == 'a') || (a:mode == 'A'))
    echo "Done nothing."
  elseif ((a:mode == 't') || (a:mode == 'T'))
    exec ":tabedit " . fnameescape(a:name)
  elseif ((a:mode == 'v') || (a:mode == 'V'))
    exec ":vsp " . fnameescape(a:name)
  elseif ((a:mode == 's') || (a:mode == 'S'))
    exec ":sp " . fnameescape(a:name)
  else 
    exec ":e " . fnameescape(a:name)
  endif
endfunction


" This function prompts a message with the open mode options and waits for a single character input
function! s:PromptOpenMode(default, name)
  echohl Question
  if (a:default == 'h')
    echo "Open " . a:name . ": [h/H]ere (default)  |  [t/T]ab  |  [v]/Vertical split  |  horizontal [s/S]plit  |  [a/A]bort     "
  elseif (a:default == 't')
    echo "Open " . a:name . ": [h/H]ere |  [t/T]ab (default)  |  [v/V]ertical split  |  horizontal [s/S]plit  |  [a/A]bort     "
  elseif (a:default == 'v')
    echo "Open " . a:name . ": [h/H]ere |  [t/T]ab  |  [v/V]ertical split (default)  |  horizontal [s/S]plit  |  [a/A]bort     "
  elseif (a:default == 's')
    echo "Open " . a:name . ": [h/H]ere |  [t/T]ab  |  [v/V]ertical split  |  horizontal [s/S]plit (default)  |  [a/A]bort     "
  endif
  echohl None
  return nr2char(getchar())
endfunction







" ================================================== 
" MAIN FUNCTION OPEN THE DIALOGUE
" ==================================================
" Launches the filemanager, waits for its return, reads in the selected filenames and opens them
function! <SID>LaunchFileDialogue()
  " Set dir as the startup directory (wither the current working directory or the directory of the file under the cursor)
  let dir = (g:vim_opendialogue_startup_directory_mode == "cwd")?getcwd():expand('%:p:h')

  if (g:vim_opendialogue_launch_terminal == 1)
    " Launch new terminal and execute shell commands: cd to directory of current file && launch ranger with --choosefile option
    exec "silent !" . g:vim_opendialogue_launch_terminal_name . " sh -c 'cd " . dir . " && " . g:vim_opendialogue_filemanager_command . g:vim_opendialogue_choose_file_filename . "'"
  else
    if (g:vim_opendialogue_startup_directory_mode == "file")
      " Save the current working directory, change it to the current files directory, launch filemanager, reset working directory
      let cwd = getcwd()
      exec "silent cd " . expand('%:p:h')
      exec "silent !" . g:vim_opendialogue_filemanager_command . g:vim_opendialogue_choose_file_filename
      exec "silent cd " . cwd
    else
      exec "silent !" . g:vim_opendialogue_filemanager_command . g:vim_opendialogue_choose_file_filename
    endif
  endif

  " Prompt for how the file should be opened (this is mainly needed because I need a blocking function call untill the ranger dialogue is closed)
  let mode = s:PromptOpenMode (g:vim_opendialogue_default_open_mode_first, "mode")
  let skip = s:IsSkipOpenMode (mode)


  " Read the g:vim_opendialogue_choose_file_filename contents
  if (!filereadable(g:vim_opendialogue_choose_file_filename))
      redraw!
      echoerr "Choosefile could not be read... Your configuration for g:vim_opendialogue_choose_file_filename is " . g:vim_opendialogue_choose_file_filename
      return
  endif
  let names = readfile(g:vim_opendialogue_choose_file_filename)
  if (empty(names))
      redraw!
      echo "No filenames specified..."
      return
  endif


  " Delete the file content of the choose file
  exec 'silent !>' . g:vim_opendialogue_choose_file_filename


  " Open the first file
  call s:SwitchOpenFile (s:ValidateOpenMode(mode, 1), names[0])

  " Open all the other files
  for name in names[1 :]
    if (skip == 0)
      " Prompt user
      let mode = s:PromptOpenMode(g:vim_opendialogue_default_open_mode, fnamemodify(name, ":t"))
      " Check if from now on skip is true
      let skip = s:IsSkipOpenMode(mode)
    endif

    " Open the file
    call s:SwitchOpenFile(s:ValidateOpenMode(mode, 0), name)
  endfor

"  redraw!
endfunction



" Define the command fore using the dialogue
command! -bar FMDialogue call <SID>LaunchFileDialogue()

