" ============================================================================
" File:        NERD_commenter.vim
" Description: vim global plugin that provides easy code commenting
" Maintainer:  Martin Grenfell <martin_grenfell at msn dot com>
" Version:     2.1.16
" Last Change: 27 June, 2008
" License:     This program is free software. It comes without any warranty,
"              to the extent permitted by applicable law. You can redistribute
"              it and/or modify it under the terms of the Do What The Fuck You
"              Want To Public License, Version 2, as published by Sam Hocevar.
"              See http://sam.zoy.org/wtfpl/COPYING for more details.
"
" ============================================================================

" Section: script init stuff {{{1
if exists("loaded_nerd_comments")
    finish
endif
if v:version < 700
    echoerr "NERDCommenter: this plugin requires vim >= 7. DOWNLOAD IT! You'll thank me later!"
    finish
endif
let loaded_nerd_comments = 1

" Section: spaces init {{{2
" Occasionally we need to grab a string of spaces so just make one here
let s:spaces = ""
while strlen(s:spaces) < 100
    let s:spaces = s:spaces . "    "
endwhile

" Function: s:InitVariable() function {{{2
" This function is used to initialise a given variable to a given value. The
" variable is only initialised if it does not exist prior
"
" Args:
"   -var: the name of the var to be initialised
"   -value: the value to initialise var to
"
" Returns:
"   1 if the var is set, 0 otherwise
function s:InitVariable(var, value)
    if !exists(a:var)
        exec 'let ' . a:var . ' = ' . "'" . a:value . "'"
        return 1
    endif
    return 0
endfunction

" Section: space string init{{{2
" When putting spaces after the left delim and before the right we use
" s:spaceStr for the space char. This way we can make it add anything after
" the left and before the right by modifying this variable
let s:spaceStr = ' '
let s:lenSpaceStr = strlen(s:spaceStr)

" Section: variable init calls {{{2
call s:InitVariable("g:NERDAllowAnyVisualDelims", 1)
call s:InitVariable("g:NERDBlockComIgnoreEmpty", 0)
call s:InitVariable("g:NERDCommentWholeLinesInVMode", 0)
call s:InitVariable("g:NERDCompactSexyComs", 0)
call s:InitVariable("g:NERDDefaultNesting", 1)
call s:InitVariable("g:NERDMenuMode", 3)
call s:InitVariable("g:NERDLPlace", "[>")
call s:InitVariable("g:NERDUsePlaceHolders", 1)
call s:InitVariable("g:NERDRemoveAltComs", 1)
call s:InitVariable("g:NERDRemoveExtraSpaces", 1)
call s:InitVariable("g:NERDRPlace", "<]")
call s:InitVariable("g:NERDShutUp", '0')
call s:InitVariable("g:NERDSpaceDelims", 0)
call s:InitVariable("g:NERDDelimiterRequests", 1)

call s:InitVariable("g:NERDMapleader", ',c')

call s:InitVariable("g:NERDAltComMap", g:NERDMapleader . 'a')
call s:InitVariable("g:NERDAppendComMap", g:NERDMapleader . 'A')
call s:InitVariable("g:NERDComAlignBothMap", g:NERDMapleader . 'b')
call s:InitVariable("g:NERDComAlignLeftMap", g:NERDMapleader . 'l')
call s:InitVariable("g:NERDComAlignRightMap", g:NERDMapleader . 'r')
call s:InitVariable("g:NERDComInInsertMap", '<C-c>')
call s:InitVariable("g:NERDComLineInvertMap", g:NERDMapleader . 'i')
call s:InitVariable("g:NERDComLineMap", g:NERDMapleader . 'c')
call s:InitVariable("g:NERDComLineNestMap", g:NERDMapleader . 'n')
call s:InitVariable("g:NERDComLineSexyMap", g:NERDMapleader . 's')
call s:InitVariable("g:NERDComLineToggleMap", g:NERDMapleader . '<space>')
call s:InitVariable("g:NERDComLineMinimalMap", g:NERDMapleader . 'm')
call s:InitVariable("g:NERDComLineYankMap", g:NERDMapleader . 'y')
call s:InitVariable("g:NERDComToEOLMap", g:NERDMapleader . '$')
call s:InitVariable("g:NERDPrependComMap", g:NERDMapleader . 'I')
call s:InitVariable("g:NERDUncomLineMap", g:NERDMapleader . 'u')
let s:NERDFileNameEscape="[]#*$%'\" ?`!&();<>\\"

" Section: Comment mapping functions, autocommands and commands {{{1
" ============================================================================
" Section: Comment enabler autocommands {{{2
" ============================================================================

if !exists("nerd_autocmds_loaded")
    let nerd_autocmds_loaded=1

    augroup commentEnablers

        "if the user enters a buffer or reads a buffer then we gotta set up
        "the comment delimiters for that new filetype
        autocmd BufEnter,BufRead * :call s:SetUpForNewFiletype(&filetype, 0)

        "if the filetype of a buffer changes, force the script to reset the
        "delims for the buffer
        autocmd Filetype * :call s:SetUpForNewFiletype(&filetype, 1)
    augroup END

endif


" Function: s:SetUpForNewFiletype(filetype) function {{{2
" This function is responsible for setting up buffer scoped variables for the
" given filetype.
"
" These variables include the comment delimiters for the given filetype and calls
" MapDelimiters or MapDelimitersWithAlternative passing in these delimiters.
"
" Args:
"   -filetype: the filetype to set delimiters for
"   -forceReset: 1 if the delimiters should be reset if they have already be
"    set for this buffer.
"
function s:SetUpForNewFiletype(filetype, forceReset)
    "if we have already set the delimiters for this buffer then dont go thru
    "it again
    if !a:forceReset && exists("b:left") && b:left != ''
        return
    endif

    let b:sexyComMarker = ''

    "check the filetype against all known filetypes to see if we have
    "hardcoded the comment delimiters to use
    if a:filetype == ""
        call s:MapDelimiters('', '')
    elseif a:filetype == "aap"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "abaqus"
        call s:MapDelimiters('**', '')
    elseif a:filetype == "abc"
        call s:MapDelimiters('%', '')
    elseif a:filetype == "acedb"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "ada"
        call s:MapDelimitersWithAlternative('--','', '--  ', '')
    elseif a:filetype == "ahdl"
        call s:MapDelimiters('--', '')
    elseif a:filetype == "ahk"
        call s:MapDelimitersWithAlternative(';', '', '/*', '*/')
    elseif a:filetype == "amiga"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "aml"
        call s:MapDelimiters('/*', '')
    elseif a:filetype == "ampl"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "ant"
        call s:MapDelimiters('<!--','-->')
    elseif a:filetype == "apache"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "apachestyle"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "asm68k"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "asm"
        call s:MapDelimitersWithAlternative(';', '', '#', '')
    elseif a:filetype == "asn"
        call s:MapDelimiters('--', '')
    elseif a:filetype == "aspvbs"
        call s:MapDelimiters('''', '')
    elseif a:filetype == "asterisk"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "asy"
        call s:MapDelimiters('//', '')
    elseif a:filetype == "atlas"
        call s:MapDelimiters('C','$')
    elseif a:filetype == "autohotkey"
        call s:MapDelimiters(';','')
    elseif a:filetype == "autoit"
        call s:MapDelimiters(';','')
    elseif a:filetype == "automake"
        call s:MapDelimitersWithAlternative('#','', 'dnl ', '')
    elseif a:filetype == "ave"
        call s:MapDelimiters("'",'')
    elseif a:filetype == "awk"
        call s:MapDelimiters('#','')
    elseif a:filetype == "basic"
        call s:MapDelimitersWithAlternative("'",'', 'REM ', '')
    elseif a:filetype == "b"
        call s:MapDelimiters('/*','*/')
    elseif a:filetype == "bbx"
        call s:MapDelimiters('%', '')
    elseif a:filetype == "bc"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "bdf"
        call s:MapDelimiters('COMMENT ', '')
    elseif a:filetype == "bib"
        call s:MapDelimiters('%','')
    elseif a:filetype == "bindzone"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "bst"
        call s:MapDelimiters('%', '')
    elseif a:filetype == "btm"
        call s:MapDelimiters('::', '')
    elseif a:filetype == "bzr"
        call s:MapDelimiters('', '')
    elseif a:filetype == "caos"
        call s:MapDelimiters('*', '')
    elseif a:filetype == "catalog"
        call s:MapDelimiters('--','--')
    elseif a:filetype == "c"
        call s:MapDelimitersWithAlternative('/*','*/', '//', '')
    elseif a:filetype == "cfg"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "cg"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "ch"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "changelog"
        call s:MapDelimiters('','')
    elseif a:filetype == "cl"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "clean"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "clipper"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "cmake"
        call s:MapDelimiters('#','')
    elseif a:filetype == "cobol"
        call s:MapDelimiters('', '')
    elseif a:filetype == "conf"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "config"
        call s:MapDelimiters('dnl ', '')
    elseif a:filetype == "context"
        call s:MapDelimiters('%','')
    elseif a:filetype == "cpp"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "crontab"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "cs"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "csc"
        call s:MapDelimiters('/*','*/')
    elseif a:filetype == "csp"
        call s:MapDelimiters('--', '')
    elseif a:filetype == "css"
        call s:MapDelimiters('/*','*/')
    elseif a:filetype == "cterm"
        call s:MapDelimiters('*', '')
    elseif a:filetype == "cupl"
        call s:MapDelimiters('/*','*/')
    elseif a:filetype == "csv"
        call s:MapDelimiters('','')
    elseif a:filetype == "cvs"
        call s:MapDelimiters('CVS:','')
    elseif a:filetype == "CVSAnnotate"
        call s:MapDelimiters('','')
    elseif a:filetype == "d"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "dcl"
        call s:MapDelimiters('$!', '')
    elseif a:filetype == "dakota"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "debchangelog"
        call s:MapDelimiters('', '')
    elseif a:filetype == "debcontrol"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "debsources"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "def"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "desktop"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "diff"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "django"
        call s:MapDelimitersWithAlternative('<!--','-->', '{#', '#}')
    elseif a:filetype == "docbk"
        call s:MapDelimiters('<!--', '-->')
    elseif a:filetype == "dns"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "dosbatch"
        call s:MapDelimitersWithAlternative('REM ','', '::', '')
    elseif a:filetype == "dosini"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "dot"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "dracula"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "dsl"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "dtd"
        call s:MapDelimiters('<!--','-->')
    elseif a:filetype == "dtml"
        call s:MapDelimiters('<dtml-comment>','</dtml-comment>')
    elseif a:filetype == "dtrace"
        call s:MapDelimiters('/*','*/')
    elseif a:filetype == "dylan"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == 'ebuild'
        call s:MapDelimiters('#', '')
    elseif a:filetype == "ecd"
        call s:MapDelimiters('#', '')
    elseif a:filetype == 'eclass'
        call s:MapDelimiters('#', '')
    elseif a:filetype == "eiffel"
        call s:MapDelimiters('--', '')
    elseif a:filetype == "elf"
        call s:MapDelimiters("'", '')
    elseif a:filetype == "elmfilt"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "erlang"
        call s:MapDelimiters('%', '')
    elseif a:filetype == "eruby"
        call s:MapDelimitersWithAlternative('<!--', '-->', '<%#', '%>')
    elseif a:filetype == "eterm"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "expect"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "exports"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "factor"
        call s:MapDelimitersWithAlternative('! ', '', '!# ', '')
    elseif a:filetype == "fetchmail"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "fgl"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "focexec"
        call s:MapDelimiters('-*', '')
    elseif a:filetype == "form"
        call s:MapDelimiters('*', '')
    elseif a:filetype == "fortran"
        call s:MapDelimiters('!', '')
    elseif a:filetype == "foxpro"
        call s:MapDelimiters('*', '')
    elseif a:filetype == "fstab"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "fvwm"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "fx"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "gams"
        call s:MapDelimiters('*', '')
    elseif a:filetype == "gdb"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "gdmo"
        call s:MapDelimiters('--', '')
    elseif a:filetype == "geek"
        call s:MapDelimiters('GEEK_COMMENT:', '')
    elseif a:filetype == "gentoo-conf-d"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "gentoo-env-d"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "gentoo-init-d"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "gentoo-make-conf"
        call s:MapDelimiters('#', '')
    elseif a:filetype == 'gentoo-package-keywords'
        call s:MapDelimiters('#', '')
    elseif a:filetype == 'gentoo-package-mask'
        call s:MapDelimiters('#', '')
    elseif a:filetype == 'gentoo-package-use'
        call s:MapDelimiters('#', '')
    elseif a:filetype == 'gitAnnotate'
        call s:MapDelimiters('', '')
    elseif a:filetype == 'gitcommit'
        call s:MapDelimiters('', '')
    elseif a:filetype == 'gitconfig'
        call s:MapDelimiters(';', '')
    elseif a:filetype == 'gitdiff'
        call s:MapDelimiters('', '')
    elseif a:filetype == "gnuplot"
        call s:MapDelimiters('#','')
    elseif a:filetype == "groovy"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "group"
        call s:MapDelimiters('','')
    elseif a:filetype == "grub"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "gtkrc"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "haskell"
        call s:MapDelimitersWithAlternative('--','', '{-', '-}')
    elseif a:filetype == "hb"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "h"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "haml"
        call s:MapDelimiters('/', '')
    elseif a:filetype == "help"
        call s:MapDelimiters('"','')
    elseif a:filetype == "hercules"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "hog"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "html"
        call s:MapDelimitersWithAlternative('<!--','-->', '//', '')
    elseif a:filetype == "htmldjango"
        call s:MapDelimitersWithAlternative('<!--','-->', '{#', '#}')
    elseif a:filetype == "htmlos"
        call s:MapDelimiters('#','/#')
    elseif a:filetype == "ia64"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "icon"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "idlang"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "idl"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "indent"
        call s:MapDelimiters('/*','*/')
    elseif a:filetype == "inform"
        call s:MapDelimiters('!', '')
    elseif a:filetype == "inittab"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "ishd"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "iss"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "ist"
        call s:MapDelimiters('%', '')
    elseif a:filetype == "jam"
        call s:MapDelimiters('/*','*/')
    elseif a:filetype == "java"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "javascript"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "jess"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "jgraph"
        call s:MapDelimiters('(*','*)')
    elseif a:filetype == "jproperties"
        call s:MapDelimiters('#','')
    elseif a:filetype == "jsp"
        call s:MapDelimiters('<%--', '--%>')
    elseif a:filetype == "kconfig"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "kix"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "kscript"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "lace"
        call s:MapDelimiters('--', '')
    elseif a:filetype == "ldif"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "lex"
        call s:MapDelimiters('/*','*/')
    elseif a:filetype == "lftp"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "lhaskell"
        call s:MapDelimiters('','')
    elseif a:filetype == "lifelines"
        call s:MapDelimiters('/*','*/')
    elseif a:filetype == "lilo"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "lilypond"
        call s:MapDelimiters('%', '')
    elseif a:filetype == "liquid"
        call s:MapDelimiters('{%', '%}')
    elseif a:filetype == "lisp"
        call s:MapDelimitersWithAlternative(';','', '#|', '|#')
    elseif a:filetype == "lite"
        call s:MapDelimiters('/*','*/')
    elseif a:filetype == "lookupfile"
        call s:MapDelimiters('', '')
    elseif a:filetype == "lotos"
        call s:MapDelimiters('(*','*)')
    elseif a:filetype == "lout"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "lprolog"
        call s:MapDelimiters('%', '')
    elseif a:filetype == "lscript"
        call s:MapDelimiters("'", '')
    elseif a:filetype == "lss"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "lua"
        call s:MapDelimitersWithAlternative('--','', '--[[', ']]')
    elseif a:filetype == "lynx"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "lytex"
        call s:MapDelimiters('%', '')
    elseif a:filetype == "m4"
        call s:MapDelimiters('dnl ', '')
    elseif a:filetype == "mail"
        call s:MapDelimiters('> ','')
    elseif a:filetype == "make"
        call s:MapDelimiters('#','')
    elseif a:filetype == "map"
        call s:MapDelimiters('%', '')
    elseif a:filetype == "maple"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "markdown"
        call s:MapDelimiters('<!--', '-->')
    elseif a:filetype == "masm"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "mason"
        call s:MapDelimiters('<% #', '%>')
    elseif a:filetype == "master"
        call s:MapDelimiters('$', '')
    elseif a:filetype == "matlab"
        call s:MapDelimiters('%', '')
    elseif a:filetype == "mel"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "mf"
        call s:MapDelimiters('%', '')
    elseif a:filetype == "mib"
        call s:MapDelimiters('--', '')
    elseif a:filetype == "mkd"
        call s:MapDelimiters('>', '')
    elseif a:filetype == "mma"
        call s:MapDelimiters('(*','*)')
    elseif a:filetype == "modconf"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "model"
        call s:MapDelimiters('$','$')
    elseif a:filetype =~ "moduala."
        call s:MapDelimiters('(*','*)')
    elseif a:filetype == "modula2"
        call s:MapDelimiters('(*','*)')
    elseif a:filetype == "modula3"
        call s:MapDelimiters('(*','*)')
    elseif a:filetype == "monk"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "mplayerconf"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "mrxvtrc"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "mush"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "muttrc"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "named"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "nasm"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "nastran"
        call s:MapDelimiters('$', '')
    elseif a:filetype == "natural"
        call s:MapDelimiters('/*', '')
    elseif a:filetype == "ncf"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "nerdtree"
        call s:MapDelimiters('', '')
    elseif a:filetype == "netdict"
        call s:MapDelimiters('', '')
    elseif a:filetype == "netrw"
        call s:MapDelimiters('', '')
    elseif a:filetype == "nqc"
        call s:MapDelimiters('/*','*/')
    elseif a:filetype == "nroff"
        call s:MapDelimiters('\"', '')
    elseif a:filetype == "nsis"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "objc"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "objcpp"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "ocaml"
        call s:MapDelimiters('(*','*)')
    elseif a:filetype == "occam"
        call s:MapDelimiters('--','')
    elseif a:filetype == "omlet"
        call s:MapDelimiters('(*','*)')
    elseif a:filetype == "omnimark"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "openroad"
        call s:MapDelimiters('//', '')
    elseif a:filetype == "opl"
        call s:MapDelimiters("REM", "")
    elseif a:filetype == "ora"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "otl"
        call s:MapDelimiters('', '')
    elseif a:filetype == "ox"
        call s:MapDelimiters('//', '')
    elseif a:filetype == "pamconf"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "pascal"
        call s:MapDelimitersWithAlternative('{','}', '(*', '*)')
    elseif a:filetype == "passwd"
        call s:MapDelimiters('','')
    elseif a:filetype == "patran"
        call s:MapDelimitersWithAlternative('$','','/*', '*/')
    elseif a:filetype == "pcap"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "pccts"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "perl"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "pfmain"
        call s:MapDelimiters('//', '')
    elseif a:filetype == "php"
        call s:MapDelimitersWithAlternative('//','','/*', '*/')
    elseif a:filetype == "phtml"
        call s:MapDelimiters('/*','*/')
    elseif a:filetype == "pic"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "pike"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "pilrc"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "pine"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "plaintex"
        call s:MapDelimiters('%','')
    elseif a:filetype == "plm"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "plsql"
        call s:MapDelimitersWithAlternative('--', '', '/*', '*/')
    elseif a:filetype == "po"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "postscr"
        call s:MapDelimiters('%', '')
    elseif a:filetype == "pov"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "povini"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "ppd"
        call s:MapDelimiters('%', '')
    elseif a:filetype == "ppwiz"
        call s:MapDelimiters(';;', '')
    elseif a:filetype == "procmail"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "progress"
        call s:MapDelimiters('/*','*/')
    elseif a:filetype == "prolog"
        call s:MapDelimitersWithAlternative('%','','/*','*/')
    elseif a:filetype == "psf"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "ptcap"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "pyrex"
        call s:MapDelimiters('#','')
    elseif a:filetype == "python"
        call s:MapDelimiters('#','')
    elseif a:filetype == "qf"
        call s:MapDelimiters('','')
    elseif a:filetype == "radiance"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "Rails-log"
        call s:MapDelimiters('', '')
    elseif a:filetype == "ratpoison"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "r"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "rc"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "readline"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "rebol"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "registry"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "remind"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "rexx"
        call s:MapDelimiters('/*','*/')
    elseif a:filetype == "rib"
        call s:MapDelimiters('#','')
    elseif a:filetype == "robots"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "rpl"
        call s:MapDelimiters('/*','*/')
    elseif a:filetype == "rst"
        call s:MapDelimiters('..', '')
    elseif a:filetype == "rtf"
        call s:MapDelimiters('', '')
    elseif a:filetype == "ruby"
        call s:MapDelimiters('#','')
    elseif a:filetype == "sa"
        call s:MapDelimiters('--','')
    elseif a:filetype == "samba"
        call s:MapDelimitersWithAlternative(';','', '#', '')
    elseif a:filetype == "sas"
        call s:MapDelimiters('/*','*/')
    elseif a:filetype == "sass"
        call s:MapDelimitersWithAlternative('//','', '/*', '')
    elseif a:filetype == "sather"
        call s:MapDelimiters('--', '')
    elseif a:filetype == "scala"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "scheme"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "scilab"
        call s:MapDelimiters('//', '')
    elseif a:filetype == "screen"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "scsh"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "sdl"
        call s:MapDelimiters('/*','*/')
    elseif a:filetype == "sed"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "selectbuf"
        call s:MapDelimiters('', '')
    elseif a:filetype == "services"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "sgml"
        call s:MapDelimiters('<!','>')
    elseif a:filetype == "sgmldecl"
        call s:MapDelimiters('--','--')
    elseif a:filetype == "sgmllnx"
        call s:MapDelimiters('<!--','-->')
    elseif a:filetype == "sicad"
        call s:MapDelimiters('*', '')
    elseif a:filetype == "simula"
        call s:MapDelimitersWithAlternative('%', '', '--', '')
    elseif a:filetype == "sinda"
        call s:MapDelimiters('$', '')
    elseif a:filetype == "skill"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "slang"
        call s:MapDelimiters('%', '')
    elseif a:filetype == "sl"
        call s:MapDelimiters('/*','*/')
    elseif a:filetype == "slice"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "slrnrc"
        call s:MapDelimiters('%', '')
    elseif a:filetype == "sm"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "smarty"
        call s:MapDelimiters('{*', '*}')
    elseif a:filetype == "smil"
        call s:MapDelimiters('<!','>')
    elseif a:filetype == "smith"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "sml"
        call s:MapDelimiters('(*','*)')
    elseif a:filetype == "snnsnet"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "snnspat"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "snnsres"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "snobol4"
        call s:MapDelimiters('*', '')
    elseif a:filetype == "spec"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "specman"
        call s:MapDelimiters('//', '')
    elseif a:filetype == "spectre"
        call s:MapDelimitersWithAlternative('//', '', '*', '')
    elseif a:filetype == "spice"
        call s:MapDelimiters('$', '')
    elseif a:filetype == "sql"
        call s:MapDelimiters('--', '')
    elseif a:filetype == "sqlforms"
        call s:MapDelimiters('--', '')
    elseif a:filetype == "sqlj"
        call s:MapDelimiters('--', '')
    elseif a:filetype == "sqr"
        call s:MapDelimiters('!', '')
    elseif a:filetype == "squid"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "st"
        call s:MapDelimiters('"','')
    elseif a:filetype == "stp"
        call s:MapDelimiters('--', '')
    elseif a:filetype == "strace"
        call s:MapDelimiters('/*','*/')
    elseif a:filetype == "sudoers"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "SVKAnnotate"
        call s:MapDelimiters('','')
    elseif a:filetype == "svn"
        call s:MapDelimiters('','')
    elseif a:filetype == "SVNAnnotate"
        call s:MapDelimiters('','')
    elseif a:filetype == "SVNcommitlog"
        call s:MapDelimiters('','')
    elseif a:filetype == "SVNdiff"
        call s:MapDelimiters('','')
    elseif a:filetype == "systemverilog"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "tads"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "taglist"
        call s:MapDelimiters('', '')
    elseif a:filetype == "tags"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "tak"
        call s:MapDelimiters('$', '')
    elseif a:filetype == "tar"
        call s:MapDelimiters('', '')
    elseif a:filetype == "tasm"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "tcl"
        call s:MapDelimiters('#','')
    elseif a:filetype == "terminfo"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "tex"
        call s:MapDelimiters('%','')
    elseif a:filetype == "text"
        call s:MapDelimiters('','')
    elseif a:filetype == "texinfo"
        call s:MapDelimiters("@c ", "")
    elseif a:filetype == "texmf"
        call s:MapDelimiters('%', '')
    elseif a:filetype == "tf"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "tidy"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "tli"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "trasys"
        call s:MapDelimiters("$", "")
    elseif a:filetype == "tsalt"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "tsscl"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "tssgm"
        call s:MapDelimiters("comment = '","'")
    elseif a:filetype == "uc"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "uil"
        call s:MapDelimiters('!', '')
    elseif a:filetype == "vb"
        call s:MapDelimiters("'","")
    elseif a:filetype == "vcscommit"
        call s:MapDelimiters('','')
    elseif a:filetype == "velocity"
        call s:MapDelimitersWithAlternative("##","", '#*', '*#')
    elseif a:filetype == "vera"
        call s:MapDelimitersWithAlternative('/*','*/','//','')
    elseif a:filetype == "verilog"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "verilog_systemverilog"
        call s:MapDelimitersWithAlternative('//','', '/*','*/')
    elseif a:filetype == "vgrindefs"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "vhdl"
        call s:MapDelimiters('--', '')
    elseif a:filetype == "vim"
        call s:MapDelimiters('"','')
    elseif a:filetype == "viminfo"
        call s:MapDelimiters('','')
    elseif a:filetype == "vimperator"
        call s:MapDelimiters('"','')
    elseif a:filetype == "virata"
        call s:MapDelimiters('%', '')
    elseif a:filetype == "vo_base"
        call s:MapDelimiters('', '')
    elseif a:filetype == "vrml"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "vsejcl"
        call s:MapDelimiters('/*', '')
    elseif a:filetype == "webmacro"
        call s:MapDelimiters('##', '')
    elseif a:filetype == "wget"
        call s:MapDelimiters('#', '')
    elseif a:filetype ==? "Wikipedia"
        call s:MapDelimiters('<!--','-->')
    elseif a:filetype == "winbatch"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "wml"
        call s:MapDelimiters('#', '')
    elseif a:filetype =~ "[^w]*sh"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "wvdial"
        call s:MapDelimiters(';', '')
    elseif a:filetype == "xdefaults"
        call s:MapDelimiters('!', '')
    elseif a:filetype == "xf86conf"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "xhtml"
        call s:MapDelimiters('<!--', '-->')
    elseif a:filetype == "xkb"
        call s:MapDelimiters('//', '')
    elseif a:filetype == "xmath"
        call s:MapDelimiters('#', '')
    elseif a:filetype == "xml"
        call s:MapDelimiters('<!--','-->')
    elseif a:filetype == "xmodmap"
        call s:MapDelimiters('!', '')
    elseif a:filetype == "xpm2"
        call s:MapDelimiters('!', '')
    elseif a:filetype == "xpm"
        call s:MapDelimiters('/*','*/')
    elseif a:filetype == "xquery"
        call s:MapDelimiters('(:', ':)')
    elseif a:filetype == "xsd"
        call s:MapDelimiters('<!--','-->')
    elseif a:filetype == "xslt"
        call s:MapDelimiters('<!--','-->')
    elseif a:filetype == "yacc"
        call s:MapDelimiters('/*','*/')
    elseif a:filetype == "yaml"
        call s:MapDelimiters('#','')
    elseif a:filetype == "z8a"
        call s:MapDelimiters(';', '')

    elseif a:filetype == ""
        call s:MapDelimitersWithAlternative("","", "", "")

        "we have not hardcoded the comment delimiters to use for this filetype so
        "get them from &commentstring.
    else
        "print a disclaimer to the user :)
        if !g:NERDShutUp
            call s:NerdEcho("Unknown filetype '".a:filetype."', setting delimiters by &commentstring.\nPleeeeease email the author of the NERD commenter with this filetype\nand its delimiters!", 0)
        endif

        "extract the delims from &commentstring
        let left= substitute(&commentstring, '\(.*\)%s.*', '\1', '')
        let right= substitute(&commentstring, '.*%s\(.*\)', '\1', 'g')

        call s:MapDelimiters(left,right)
    endif
endfunction

" Function: s:MapDelimiters(left, right) function {{{2
" This function is a wrapper for s:MapDelimiters(left, right, leftAlt, rightAlt, useAlt) and is called when there
" is no alternative comment delimiters for the current filetype
"
" Args:
"   -left: the left comment delimiter
"   -right: the right comment delimiter
function s:MapDelimiters(left, right)
    call s:MapDelimitersWithAlternative(a:left, a:right, "", "")
endfunction

" Function: s:MapDelimitersWithAlternative(left, right, leftAlt, rightAlt) function {{{2
" this function sets up the comment delimiter buffer variables
"
" Args:
"   -left:  the string defining the comment start delimiter
"   -right: the string defining the comment end delimiter
"   -leftAlt:  the string for the alternative comment style defining the comment start delimiter
"   -rightAlt: the string for the alternative comment style defining the comment end delimiter
function s:MapDelimitersWithAlternative(left, right, leftAlt, rightAlt)
    if !exists('g:NERD_' . &filetype . '_alt_style')
        let b:left = a:left
        let b:right = a:right
        let b:leftAlt = a:leftAlt
        let b:rightAlt = a:rightAlt
    else
        let b:left = a:leftAlt
        let b:right = a:rightAlt
        let b:leftAlt = a:left
        let b:rightAlt = a:right
    endif
endfunction

" Function: s:SwitchToAlternativeDelimiters(printMsgs) function {{{2
" This function is used to swap the delimiters that are being used to the
" alternative delimiters for that filetype. For example, if a c++ file is
" being edited and // comments are being used, after this function is called
" /**/ comments will be used.
"
" Args:
"   -printMsgs: if this is 1 then a message is echoed to the user telling them
"    if this function changed the delimiters or not
function s:SwitchToAlternativeDelimiters(printMsgs)
    "if both of the alternative delimiters are empty then there is no
    "alternative comment style so bail out
    if b:leftAlt == "" && b:rightAlt == ""
        if a:printMsgs
            call s:NerdEcho("Cannot use alternative delimiters, none are specified", 0)
        endif
        return 0
    endif

    "save the current delimiters
    let tempLeft = b:left
    let tempRight = b:right

    "swap current delimiters for alternative
    let b:left = b:leftAlt
    let b:right = b:rightAlt

    "set the previously current delimiters to be the new alternative ones
    let b:leftAlt = tempLeft
    let b:rightAlt = tempRight

    "tell the user what comment delimiters they are now using
    if a:printMsgs
        let leftNoEsc = b:left
        let rightNoEsc = b:right
        call s:NerdEcho("Now using " . leftNoEsc . " " . rightNoEsc . " to delimit comments", 1)
    endif

    return 1
endfunction


" Section: Comment delimiter add/removal functions {{{1
" ============================================================================
" Function: s:AppendCommentToLine(){{{2
" This function appends comment delimiters at the EOL and places the cursor in
" position to start typing the comment
function s:AppendCommentToLine()
    let left = s:GetLeft(0,1,0)
    let right = s:GetRight(0,1,0)

    " get the len of the right delim
    let lenRight = strlen(right)

    let isLineEmpty = strlen(getline(".")) == 0
    let insOrApp = (isLineEmpty==1 ? 'i' : 'A')

    "stick the delimiters down at the end of the line. We have to format the
    "comment with spaces as appropriate
    execute ":normal " . insOrApp . (isLineEmpty ? '' : ' ') . left . right . " "

    " if there is a right delimiter then we gotta move the cursor left
    " by the len of the right delimiter so we insert between the delimiters
    if lenRight > 0
        let leftMoveAmount = lenRight
        execute ":normal " . leftMoveAmount . "h"
    endif
    startinsert
endfunction

" Function: s:CommentBlock(top, bottom, lSide, rSide, forceNested ) {{{2
" This function is used to comment out a region of code. This region is
" specified as a bounding box by arguments to the function.
"
" Args:
"   -top: the line number for the top line of code in the region
"   -bottom: the line number for the bottom line of code in the region
"   -lSide: the column number for the left most column in the region
"   -rSide: the column number for the right most column in the region
"   -forceNested: a flag indicating whether comments should be nested
function s:CommentBlock(top, bottom, lSide, rSide, forceNested )
    " we need to create local copies of these arguments so we can modify them
    let top = a:top
    let bottom = a:bottom
    let lSide = a:lSide
    let rSide = a:rSide

    "if the top or bottom line starts with tabs we have to adjust the left and
    "right boundaries so that they are set as though the tabs were spaces
    let topline = getline(top)
    let bottomline = getline(bottom)
    if s:HasLeadingTabs(topline, bottomline)

        "find out how many tabs are in the top line and adjust the left
        "boundary accordingly
        let numTabs = s:NumberOfLeadingTabs(topline)
        if lSide < numTabs
            let lSide = &ts * lSide
        else
            let lSide = (lSide - numTabs) + (&ts * numTabs)
        endif

        "find out how many tabs are in the bottom line and adjust the right
        "boundary accordingly
        let numTabs = s:NumberOfLeadingTabs(bottomline)
        let rSide = (rSide - numTabs) + (&ts * numTabs)
    endif

    "we must check that bottom IS actually below top, if it is not then we
    "swap top and bottom. Similarly for left and right.
    if bottom < top
        let temp = top
        let top = bottom
        let bottom = top
    endif
    if rSide < lSide
        let temp = lSide
        let lSide = rSide
        let rSide = temp
    endif

    "if the current delimiters arent multipart then we will switch to the
    "alternative delims (if THEY are) as the comment will be better and more
    "accurate with multipart delims
    let switchedDelims = 0
    if !s:Multipart() && g:NERDAllowAnyVisualDelims && s:AltMultipart()
        let switchedDelims = 1
        call s:SwitchToAlternativeDelimiters(0)
    endif

    "start the commenting from the top and keep commenting till we reach the
    "bottom
    let currentLine=top
    while currentLine <= bottom

        "check if we are allowed to comment this line
        if s:CanCommentLine(a:forceNested, currentLine)

            "convert the leading tabs into spaces
            let theLine = getline(currentLine)
            let lineHasLeadTabs = s:HasLeadingTabs(theLine)
            if lineHasLeadTabs
                let theLine = s:ConvertLeadingTabsToSpaces(theLine)
            endif

            "dont comment lines that begin after the right boundary of the
            "block unless the user has specified to do so
            if theLine !~ '^ \{' . rSide . '\}' || !g:NERDBlockComIgnoreEmpty

                "attempt to place the cursor in on the left of the boundary box,
                "then check if we were successful, if not then we cant comment this
                "line
                call setline(currentLine, theLine)
                if s:CanPlaceCursor(currentLine, lSide)

                    let leftSpaced = s:GetLeft(0,1,0)
                    let rightSpaced = s:GetRight(0,1,0)

                    "stick the left delimiter down
                    let theLine = strpart(theLine, 0, lSide-1) . leftSpaced . strpart(theLine, lSide-1)

                    if s:Multipart()
                        "stick the right delimiter down
                        let theLine = strpart(theLine, 0, rSide+strlen(leftSpaced)) . rightSpaced . strpart(theLine, rSide+strlen(leftSpaced))

                        let firstLeftDelim = s:FindDelimiterIndex(b:left, theLine)
                        let lastRightDelim = s:LastIndexOfDelim(b:right, theLine)

                        if firstLeftDelim != -1 && lastRightDelim != -1
                            let searchStr = strpart(theLine, 0, lastRightDelim)
                            let searchStr = strpart(searchStr, firstLeftDelim+strlen(b:left))

                            "replace the outter most delims in searchStr with
                            "place-holders
                            let theLineWithPlaceHolders = s:ReplaceDelims(b:left, b:right, g:NERDLPlace, g:NERDRPlace, searchStr)

                            "add the right delimiter onto the line
                            let theLine = strpart(theLine, 0, firstLeftDelim+strlen(b:left)) . theLineWithPlaceHolders . strpart(theLine, lastRightDelim)
                        endif
                    endif
                endif
            endif

            "restore tabs if needed
            if lineHasLeadTabs
                let theLine = s:ConvertLeadingSpacesToTabs(theLine)
            endif

            call setline(currentLine, theLine)
        endif

        let currentLine = currentLine + 1
    endwhile

    "if we switched delims then we gotta go back to what they were before
    if switchedDelims == 1
        call s:SwitchToAlternativeDelimiters(0)
    endif
endfunction

" Function: s:CommentLines(forceNested, alignLeft, alignRight, firstLine, lastLine) {{{2
" This function comments a range of lines.
"
" Args:
"   -forceNested: a flag indicating whether the called is requesting the comment
"    to be nested if need be
"   -alignRight/alignLeft: 0/1 if the comments delimiters should/shouldnt be
"    aligned left/right
"   -firstLine/lastLine: the top and bottom lines to comment
function s:CommentLines(forceNested, alignLeft, alignRight, firstLine, lastLine)
    " we need to get the left and right indexes of the leftmost char in the
    " block of of lines and the right most char so that we can do alignment of
    " the delimiters if the user has specified
    let leftAlignIndx = s:LeftMostIndx(a:forceNested, 0, a:firstLine, a:lastLine)
    let rightAlignIndx = s:RightMostIndx(a:forceNested, 0, a:firstLine, a:lastLine)

    " gotta add the length of the left delimiter onto the rightAlignIndx cos
    " we'll be adding a left delim to the line
    let rightAlignIndx = rightAlignIndx + strlen(s:GetLeft(0,1,0))

    " now we actually comment the lines. Do it line by line
    let currentLine = a:firstLine
    while currentLine <= a:lastLine

        " get the next line, check commentability and convert spaces to tabs
        let theLine = getline(currentLine)
        let lineHasLeadingTabs = s:HasLeadingTabs(theLine)
        let theLine = s:ConvertLeadingTabsToSpaces(theLine)
        if s:CanCommentLine(a:forceNested, currentLine)
            "if the user has specified forceNesting then we check to see if we
            "need to switch delimiters for place-holders
            if a:forceNested && g:NERDUsePlaceHolders
                let theLine = s:SwapOutterMultiPartDelimsForPlaceHolders(theLine)
            endif

            " find out if the line is commented using normal delims and/or
            " alternate ones
            let isCommented = s:IsCommented(b:left, b:right, theLine) || s:IsCommented(b:leftAlt, b:rightAlt, theLine)

            " check if we can comment this line
            if !isCommented || g:NERDUsePlaceHolders || s:Multipart()
                if a:alignLeft
                    let theLine = s:AddLeftDelimAligned(s:GetLeft(0,1,0), theLine, leftAlignIndx)
                else
                    let theLine = s:AddLeftDelim(s:GetLeft(0,1,0), theLine)
                endif
                if a:alignRight
                    let theLine = s:AddRightDelimAligned(s:GetRight(0,1,0), theLine, rightAlignIndx)
                else
                    let theLine = s:AddRightDelim(s:GetRight(0,1,0), theLine)
                endif
            endif
        endif

        " restore leading tabs if appropriate
        if lineHasLeadingTabs
            let theLine = s:ConvertLeadingSpacesToTabs(theLine)
        endif

        " we are done with this line
        call setline(currentLine, theLine)
        let currentLine = currentLine + 1
    endwhile

endfunction

" Function: s:CommentLinesMinimal(firstLine, lastLine) {{{2
" This function comments a range of lines in a minimal style. I
"
" Args:
"   -firstLine/lastLine: the top and bottom lines to comment
function s:CommentLinesMinimal(firstLine, lastLine)
    "check that minimal comments can be done on this filetype
    if !s:HasMultipartDelims()
        throw 'NERDCommenter.Delimiters exception: Minimal comments can only be used for filetypes that have multipart delimiters'
    endif

    "if we need to use place holders for the comment, make sure they are
    "enabled for this filetype
    if !g:NERDUsePlaceHolders && s:DoesBlockHaveMultipartDelim(a:firstLine, a:lastLine)
        throw 'NERDCommenter.Settings exception: Placeoholders are required but disabled.'
    endif

    "get the left and right delims to smack on
    let left = s:GetSexyComLeft(g:NERDSpaceDelims,0)
    let right = s:GetSexyComRight(g:NERDSpaceDelims,0)

    "make sure all multipart delims on the lines are replaced with
    "placeholders to prevent illegal syntax
    let currentLine = a:firstLine
    while(currentLine <= a:lastLine)
        let theLine = getline(currentLine)
        let theLine = s:ReplaceDelims(left, right, g:NERDLPlace, g:NERDRPlace, theLine)
        call setline(currentLine, theLine)
        let currentLine = currentLine + 1
    endwhile

    "add the delim to the top line
    let theLine = getline(a:firstLine)
    let lineHasLeadingTabs = s:HasLeadingTabs(theLine)
    let theLine = s:ConvertLeadingTabsToSpaces(theLine)
    let theLine = s:AddLeftDelim(left, theLine)
    if lineHasLeadingTabs
        let theLine = s:ConvertLeadingSpacesToTabs(theLine)
    endif
    call setline(a:firstLine, theLine)

    "add the delim to the bottom line
    let theLine = getline(a:lastLine)
    let lineHasLeadingTabs = s:HasLeadingTabs(theLine)
    let theLine = s:ConvertLeadingTabsToSpaces(theLine)
    let theLine = s:AddRightDelim(right, theLine)
    if lineHasLeadingTabs
        let theLine = s:ConvertLeadingSpacesToTabs(theLine)
    endif
    call setline(a:lastLine, theLine)
endfunction

" Function: s:CommentLinesSexy(topline, bottomline) function {{{2
" This function is used to comment lines in the 'Sexy' style. eg in c:
" /*
"  * This is a sexy comment
"  */
" Args:
"   -topline: the line num of the top line in the sexy comment
"   -bottomline: the line num of the bottom line in the sexy comment
function s:CommentLinesSexy(topline, bottomline)
    let left = s:GetSexyComLeft(0, 0)
    let right = s:GetSexyComRight(0, 0)

    "check if we can do a sexy comment with the available delimiters
    if left == -1 || right == -1
        throw 'NERDCommenter.Delimiters exception: cannot perform sexy comments with available delimiters.'
    endif

    "make sure the lines arent already commented sexually
    if !s:CanSexyCommentLines(a:topline, a:bottomline)
        throw 'NERDCommenter.Nesting exception: cannot nest sexy comments'
    endif


    let sexyComMarker = s:GetSexyComMarker(0,0)
    let sexyComMarkerSpaced = s:GetSexyComMarker(1,0)


    " we jam the comment as far to the right as possible
    let leftAlignIndx = s:LeftMostIndx(1, 1, a:topline, a:bottomline)

    "check if we should use the compact style i.e that the left/right
    "delimiters should appear on the first and last lines of the code and not
    "on separate lines above/below the first/last lines of code
    if g:NERDCompactSexyComs
        let spaceString = (g:NERDSpaceDelims ? s:spaceStr : '')

        "comment the top line
        let theLine = getline(a:topline)
        let lineHasTabs = s:HasLeadingTabs(theLine)
        if lineHasTabs
            let theLine = s:ConvertLeadingTabsToSpaces(theLine)
        endif
        let theLine = s:SwapOutterMultiPartDelimsForPlaceHolders(theLine)
        let theLine = s:AddLeftDelimAligned(left . spaceString, theLine, leftAlignIndx)
        if lineHasTabs
            let theLine = s:ConvertLeadingSpacesToTabs(theLine)
        endif
        call setline(a:topline, theLine)

        "comment the bottom line
        if a:bottomline != a:topline
            let theLine = getline(a:bottomline)
            let lineHasTabs = s:HasLeadingTabs(theLine)
            if lineHasTabs
                let theLine = s:ConvertLeadingTabsToSpaces(theLine)
            endif
            let theLine = s:SwapOutterMultiPartDelimsForPlaceHolders(theLine)
        endif
        let theLine = s:AddRightDelim(spaceString . right, theLine)
        if lineHasTabs
            let theLine = s:ConvertLeadingSpacesToTabs(theLine)
        endif
        call setline(a:bottomline, theLine)
    else

        " add the left delimiter one line above the lines that are to be commented
        call cursor(a:topline, 1)
        execute 'normal! O'
        call setline(a:topline, strpart(s:spaces, 0, leftAlignIndx) . left )

        " add the right delimiter after bottom line (we have to add 1 cos we moved
        " the lines down when we added the left delim
        call cursor(a:bottomline+1, 1)
        execute 'normal! o'
        call setline(a:bottomline+2, strpart(s:spaces, 0, leftAlignIndx) . strpart(s:spaces, 0, strlen(left)-strlen(sexyComMarker)) . right )

    endif

    " go thru each line adding the sexyComMarker marker to the start of each
    " line in the appropriate place to align them with the comment delims
    let currentLine = a:topline+1
    while currentLine <= a:bottomline + !g:NERDCompactSexyComs
        " get the line and convert the tabs to spaces
        let theLine = getline(currentLine)
        let lineHasTabs = s:HasLeadingTabs(theLine)
        if lineHasTabs
            let theLine = s:ConvertLeadingTabsToSpaces(theLine)
        endif

        let theLine = s:SwapOutterMultiPartDelimsForPlaceHolders(theLine)

        " add the sexyComMarker
        let theLine = strpart(s:spaces, 0, leftAlignIndx) . strpart(s:spaces, 0, strlen(left)-strlen(sexyComMarker)) . sexyComMarkerSpaced . strpart(theLine, leftAlignIndx)

        if lineHasTabs
            let theLine = s:ConvertLeadingSpacesToTabs(theLine)
        endif


        " set the line and move onto the next one
        call setline(currentLine, theLine)
        let currentLine = currentLine + 1
    endwhile

endfunction

" Function: s:CommentLinesToggle(forceNested, firstLine, lastLine) {{{2
" Applies "toggle" commenting to the given range of lines
"
" Args:
"   -forceNested: a flag indicating whether the called is requesting the comment
"    to be nested if need be
"   -firstLine/lastLine: the top and bottom lines to comment
function s:CommentLinesToggle(forceNested, firstLine, lastLine)
    let currentLine = a:firstLine
    while currentLine <= a:lastLine

        " get the next line, check commentability and convert spaces to tabs
        let theLine = getline(currentLine)
        let lineHasLeadingTabs = s:HasLeadingTabs(theLine)
        let theLine = s:ConvertLeadingTabsToSpaces(theLine)
        if s:CanToggleCommentLine(a:forceNested, currentLine)

            "if the user has specified forceNesting then we check to see if we
            "need to switch delimiters for place-holders
            if g:NERDUsePlaceHolders
                let theLine = s:SwapOutterMultiPartDelimsForPlaceHolders(theLine)
            endif

            let theLine = s:AddLeftDelim(s:GetLeft(0, 1, 0), theLine)
            let theLine = s:AddRightDelim(s:GetRight(0, 1, 0), theLine)
        endif

        " restore leading tabs if appropriate
        if lineHasLeadingTabs
            let theLine = s:ConvertLeadingSpacesToTabs(theLine)
        endif

        " we are done with this line
        call setline(currentLine, theLine)
        let currentLine = currentLine + 1
    endwhile

endfunction

" Function: s:CommentRegion(topline, topCol, bottomLine, bottomCol) function {{{2
" This function comments chunks of text selected in visual mode.
" It will comment exactly the text that they have selected.
" Args:
"   -topLine: the line num of the top line in the sexy comment
"   -topCol: top left col for this comment
"   -bottomline: the line num of the bottom line in the sexy comment
"   -bottomCol: the bottom right col for this comment
"   -forceNested: whether the caller wants comments to be nested if the
"    line(s) are already commented
function s:CommentRegion(topLine, topCol, bottomLine, bottomCol, forceNested)

    "switch delims (if we can) if the current set isnt multipart
    let switchedDelims = 0
    if !s:Multipart() && s:AltMultipart() && !g:NERDAllowAnyVisualDelims
        let switchedDelims = 1
        call s:SwitchToAlternativeDelimiters(0)
    endif

    "if there is only one line in the comment then just do it
    if a:topLine == a:bottomLine
        call s:CommentBlock(a:topLine, a:bottomLine, a:topCol, a:bottomCol, a:forceNested)

    "there are multiple lines in the comment
    else
        "comment the top line
        call s:CommentBlock(a:topLine, a:topLine, a:topCol, strlen(getline(a:topLine)), a:forceNested)

        "comment out all the lines in the middle of the comment
        let topOfRange = a:topLine+1
        let bottomOfRange = a:bottomLine-1
        if topOfRange <= bottomOfRange
            call s:CommentLines(a:forceNested, 0, 0, topOfRange, bottomOfRange)
        endif

        "comment the bottom line
        let bottom = getline(a:bottomLine)
        let numLeadingSpacesTabs = strlen(substitute(bottom, '^\([ \t]*\).*$', '\1', ''))
        call s:CommentBlock(a:bottomLine, a:bottomLine, numLeadingSpacesTabs+1, a:bottomCol, a:forceNested)

    endif

    "stick the cursor back on the char it was on before the comment
    call cursor(a:topLine, a:topCol + strlen(b:left) + g:NERDSpaceDelims)

    "if we switched delims then we gotta go back to what they were before
    if switchedDelims == 1
        call s:SwitchToAlternativeDelimiters(0)
    endif

endfunction

" Function: s:InvertComment(firstLine, lastLine) function {{{2
" Inverts the comments on the lines between and including the given line
" numbers i.e all commented lines are uncommented and vice versa
" Args:
"   -firstLine: the top of the range of lines to be inverted
"   -lastLine: the bottom of the range of lines to be inverted
function s:InvertComment(firstLine, lastLine)

    " go thru all lines in the given range
    let currentLine = a:firstLine
    while currentLine <= a:lastLine
        let theLine = getline(currentLine)

        let sexyComBounds = s:FindBoundingLinesOfSexyCom(currentLine)

        " if the line is commented normally, uncomment it
        if s:IsCommentedFromStartOfLine(b:left, theLine) || s:IsCommentedFromStartOfLine(b:leftAlt, theLine)
            call s:UncommentLines(currentLine, currentLine)
            let currentLine = currentLine + 1

        " check if the line is commented sexually
        elseif !empty(sexyComBounds)
            let numLinesBeforeSexyComRemoved = s:NumLinesInBuf()
            call s:UncommentLinesSexy(sexyComBounds[0], sexyComBounds[1])

            "move to the line after last line of the sexy comment
            let numLinesAfterSexyComRemoved = s:NumLinesInBuf()
            let currentLine = bottomBound - (numLinesBeforeSexyComRemoved - numLinesAfterSexyComRemoved) + 1

        " the line isnt commented
        else
            call s:CommentLinesToggle(1, currentLine, currentLine)
            let currentLine = currentLine + 1
        endif

    endwhile
endfunction

" Function: NERDComment(isVisual, alignLeft, alignRight, type) function {{{2
" This function is a Wrapper for the main commenting functions
"
" Args:
"   -isVisual: a flag indicating whether the comment is requested in visual
"    mode or not
"   -type: the type of commenting requested. Can be 'sexy', 'invert',
"    'minimal', 'toggle', 'alignLeft', 'alignRight', 'alignBoth', 'norm',
"    'nested', 'toEOL', 'prepend', 'append', 'insert', 'uncomment', 'yank'
function! NERDComment(isVisual, type) range
    " we want case sensitivity when commenting
    let oldIgnoreCase = &ignorecase
    set noignorecase

    if a:isVisual
        let firstLine = line("'<")
        let lastLine = line("'>")
        let firstCol = col("'<")
        let lastCol = col("'>") - (&selection == 'exclusive' ? 1 : 0)
    else
        let firstLine = a:firstline
        let lastLine = a:lastline
    endif

    let countWasGiven = (a:isVisual == 0 && firstLine != lastLine)

    let forceNested = (a:type == 'nested' || g:NERDDefaultNesting)

    if a:type == 'norm' || a:type == 'nested'
        if a:isVisual && visualmode() == ""
            call s:CommentBlock(firstLine, lastLine, firstCol, lastCol, forceNested)
        elseif a:isVisual && visualmode() == "v" && (g:NERDCommentWholeLinesInVMode==0 || (g:NERDCommentWholeLinesInVMode==2 && s:HasMultipartDelims()))
            call s:CommentRegion(firstLine, firstCol, lastLine, lastCol, forceNested)
        else
            call s:CommentLines(forceNested, 0, 0, firstLine, lastLine)
        endif

    elseif a:type == 'alignLeft' || a:type == 'alignRight' || a:type == 'alignBoth'
        let alignLeft = (a:type == 'alignLeft' || a:type == 'alignBoth')
        let alignRight = (a:type == 'alignRight' || a:type == 'alignBoth')
        call s:CommentLines(forceNested, alignLeft, alignRight, firstLine, lastLine)

    elseif a:type == 'invert'
        call s:InvertComment(firstLine, lastLine)

    elseif a:type == 'sexy'
        try
            call s:CommentLinesSexy(firstLine, lastLine)
        catch /NERDCommenter.Delimiters/
            call s:CommentLines(forceNested, 0, 0, firstLine, lastLine)
        catch /NERDCommenter.Nesting/
            call s:NerdEcho("Sexy comment aborted. Nested sexy cannot be nested", 0)
        endtry

    elseif a:type == 'toggle'
        let theLine = getline(firstLine)

        if s:IsInSexyComment(firstLine) || s:IsCommentedFromStartOfLine(b:left, theLine) || s:IsCommentedFromStartOfLine(b:leftAlt, theLine)
            call s:UncommentLines(firstLine, lastLine)
        else
            call s:CommentLinesToggle(forceNested, firstLine, lastLine)
        endif

    elseif a:type == 'minimal'
        try
            call s:CommentLinesMinimal(firstLine, lastLine)
        catch /NERDCommenter.Delimiters/
            call s:NerdEcho("Minimal comments can only be used for filetypes that have multipart delimiters.", 0)
        catch /NERDCommenter.Settings/
            call s:NerdEcho("Place holders are required but disabled.", 0)
        endtry

    elseif a:type == 'toEOL'
        call s:SaveScreenState()
        call s:CommentBlock(firstLine, firstLine, col("."), col("$")-1, 1)
        call s:RestoreScreenState()

    elseif a:type == 'prepend'
        call s:PrependCommentToLine()

    elseif a:type == 'append'
        call s:AppendCommentToLine()

    elseif a:type == 'insert'
        call s:PlaceDelimitersAndInsBetween()

    elseif a:type == 'uncomment'
        call s:UncommentLines(firstLine, lastLine)

    elseif a:type == 'yank'
        if a:isVisual
            normal gvy
        elseif countWasGiven
            execute firstLine .','. lastLine .'yank'
        else
            normal Y
        endif
        execute firstLine .','. lastLine .'call NERDComment('. a:isVisual .', "norm")'
    endif

    let &ignorecase = oldIgnoreCase
endfunction

" Function: s:PlaceDelimitersAndInsBetween() function {{{2
" This is function is called to place comment delimiters down and place the
" cursor between them
function s:PlaceDelimitersAndInsBetween()
    " get the left and right delimiters without any escape chars in them
    let left = s:GetLeft(0, 1, 0)
    let right = s:GetRight(0, 1, 0)

    let theLine = getline(".")
    let lineHasLeadTabs = s:HasLeadingTabs(theLine) || (theLine =~ '^ *$' && !&expandtab)

    "convert tabs to spaces and adjust the cursors column to take this into
    "account
    let untabbedCol = s:UntabbedCol(theLine, col("."))
    call setline(line("."), s:ConvertLeadingTabsToSpaces(theLine))
    call cursor(line("."), untabbedCol)

    " get the len of the right delim
    let lenRight = strlen(right)

    let isDelimOnEOL = col(".") >= strlen(getline("."))

    " if the cursor is in the first col then we gotta insert rather than
    " append the comment delimiters here
    let insOrApp = (col(".")==1 ? 'i' : 'a')

    " place the delimiters down. We do it differently depending on whether
    " there is a left AND right delimiter
    if lenRight > 0
        execute ":normal " . insOrApp . left . right
        execute ":normal " . lenRight . "h"
    else
        execute ":normal " . insOrApp . left

        " if we are tacking the delim on the EOL then we gotta add a space
        " after it cos when we go out of insert mode the cursor will move back
        " one and the user wont be in position to type the comment.
        if isDelimOnEOL
            execute 'normal a '
        endif
    endif
    normal l

    "if needed convert spaces back to tabs and adjust the cursors col
    "accordingly
    if lineHasLeadTabs
        let tabbedCol = s:TabbedCol(getline("."), col("."))
        call setline(line("."), s:ConvertLeadingSpacesToTabs(getline(".")))
        call cursor(line("."), tabbedCol)
    endif

    startinsert
endfunction

" Function: s:PrependCommentToLine(){{{2
" This function prepends comment delimiters to the start of line and places
" the cursor in position to start typing the comment
function s:PrependCommentToLine()
    " get the left and right delimiters without any escape chars in them
    let left = s:GetLeft(0, 1, 0)
    let right = s:GetRight(0, 1, 0)

    " get the len of the right delim
    let lenRight = strlen(right)


    "if the line is empty then we need to know about this later on
    let isLineEmpty = strlen(getline(".")) == 0

    "stick the delimiters down at the start of the line. We have to format the
    "comment with spaces as appropriate
    if lenRight > 0
        execute ":normal I" . left . right
    else
        execute ":normal I" . left
    endif

    " if there is a right delimiter then we gotta move the cursor left
    " by the len of the right delimiter so we insert between the delimiters
    if lenRight > 0
        let leftMoveAmount = lenRight
        execute ":normal " . leftMoveAmount . "h"
    endif
    normal l

    "if the line was empty then we gotta add an extra space on the end because
    "the cursor will move back one more at the end of the last "execute"
    "command
    if isLineEmpty && lenRight == 0
        execute ":normal a "
    endif

    startinsert
endfunction
" Function: s:RemoveDelimiters(left, right, line) {{{2
" this function is called to remove the first left comment delimiter and the
" last right delimiter of the given line.
"
" The args left and right must be strings. If there is no right delimiter (as
" is the case for e.g vim file comments) them the arg right should be ""
"
" Args:
"   -left: the left comment delimiter
"   -right: the right comment delimiter
"   -line: the line to remove the delimiters from
function s:RemoveDelimiters(left, right, line)

    let l:left = a:left
    let l:right = a:right
    let lenLeft = strlen(left)
    let lenRight = strlen(right)

    let delimsSpaced = (g:NERDSpaceDelims || g:NERDRemoveExtraSpaces)

    let line = a:line

    "look for the left delimiter, if we find it, remove it.
    let leftIndx = s:FindDelimiterIndex(a:left, line)
    if leftIndx != -1
        let line = strpart(line, 0, leftIndx) . strpart(line, leftIndx+lenLeft)

        "if the user has specified that there is a space after the left delim
        "then check for the space and remove it if it is there
        if delimsSpaced && strpart(line, leftIndx, s:lenSpaceStr) == s:spaceStr
            let line = strpart(line, 0, leftIndx) . strpart(line, leftIndx+s:lenSpaceStr)
        endif
    endif

    "look for the right delimiter, if we find it, remove it
    let rightIndx = s:FindDelimiterIndex(a:right, line)
    if rightIndx != -1
        let line = strpart(line, 0, rightIndx) . strpart(line, rightIndx+lenRight)

        "if the user has specified that there is a space before the right delim
        "then check for the space and remove it if it is there
        if delimsSpaced && strpart(line, rightIndx-s:lenSpaceStr, s:lenSpaceStr) == s:spaceStr && s:Multipart()
            let line = strpart(line, 0, rightIndx-s:lenSpaceStr) . strpart(line, rightIndx)
        endif
    endif

    return line
endfunction

" Function: s:UncommentLines(topLine, bottomLine) {{{2
" This function uncomments the given lines
"
" Args:
" topLine: the top line of the visual selection to uncomment
" bottomLine: the bottom line of the visual selection to uncomment
function s:UncommentLines(topLine, bottomLine)
    "make local copies of a:firstline and a:lastline and, if need be, swap
    "them around if the top line is below the bottom
    let l:firstline = a:topLine
    let l:lastline = a:bottomLine
    if firstline > lastline
        let firstline = lastline
        let lastline = a:topLine
    endif

    "go thru each line uncommenting each line removing sexy comments
    let currentLine = firstline
    while currentLine <= lastline

        "check the current line to see if it is part of a sexy comment
        let sexyComBounds = s:FindBoundingLinesOfSexyCom(currentLine)
        if !empty(sexyComBounds)

            "we need to store the num lines in the buf before the comment is
            "removed so we know how many lines were removed when the sexy com
            "was removed
            let numLinesBeforeSexyComRemoved = s:NumLinesInBuf()

            call s:UncommentLinesSexy(sexyComBounds[0], sexyComBounds[1])

            "move to the line after last line of the sexy comment
            let numLinesAfterSexyComRemoved = s:NumLinesInBuf()
            let numLinesRemoved = numLinesBeforeSexyComRemoved - numLinesAfterSexyComRemoved
            let currentLine = sexyComBounds[1] - numLinesRemoved + 1
            let lastline = lastline - numLinesRemoved

        "no sexy com was detected so uncomment the line as normal
        else
            call s:UncommentLinesNormal(currentLine, currentLine)
            let currentLine = currentLine + 1
        endif
    endwhile

endfunction

" Function: s:UncommentLinesSexy(topline, bottomline) {{{2
" This function removes all the comment characters associated with the sexy
" comment spanning the given lines
" Args:
"   -topline/bottomline: the top/bottom lines of the sexy comment
function s:UncommentLinesSexy(topline, bottomline)
    let left = s:GetSexyComLeft(0,1)
    let right = s:GetSexyComRight(0,1)


    "check if it is even possible for sexy comments to exist with the
    "available delimiters
    if left == -1 || right == -1
        throw 'NERDCommenter.Delimiters exception: cannot uncomment sexy comments with available delimiters.'
    endif

    let leftUnEsc = s:GetSexyComLeft(0,0)
    let rightUnEsc = s:GetSexyComRight(0,0)

    let sexyComMarker = s:GetSexyComMarker(0, 1)
    let sexyComMarkerUnEsc = s:GetSexyComMarker(0, 0)

    "the markerOffset is how far right we need to move the sexyComMarker to
    "line it up with the end of the left delim
    let markerOffset = strlen(leftUnEsc)-strlen(sexyComMarkerUnEsc)

    " go thru the intermediate lines of the sexy comment and remove the
    " sexy comment markers (eg the '*'s on the start of line in a c sexy
    " comment)
    let currentLine = a:topline+1
    while currentLine < a:bottomline
        let theLine = getline(currentLine)

        " remove the sexy comment marker from the line. We also remove the
        " space after it if there is one and if appropriate options are set
        let sexyComMarkerIndx = stridx(theLine, sexyComMarkerUnEsc)
        if strpart(theLine, sexyComMarkerIndx+strlen(sexyComMarkerUnEsc), s:lenSpaceStr) == s:spaceStr  && g:NERDSpaceDelims
            let theLine = strpart(theLine, 0, sexyComMarkerIndx - markerOffset) . strpart(theLine, sexyComMarkerIndx+strlen(sexyComMarkerUnEsc)+s:lenSpaceStr)
        else
            let theLine = strpart(theLine, 0, sexyComMarkerIndx - markerOffset) . strpart(theLine, sexyComMarkerIndx+strlen(sexyComMarkerUnEsc))
        endif

        let theLine = s:SwapOutterPlaceHoldersForMultiPartDelims(theLine)

        let theLine = s:ConvertLeadingWhiteSpace(theLine)

        " move onto the next line
        call setline(currentLine, theLine)
        let currentLine = currentLine + 1
    endwhile

    " gotta make a copy of a:bottomline cos we modify the position of the
    " last line  it if we remove the topline
    let bottomline = a:bottomline

    " get the first line so we can remove the left delim from it
    let theLine = getline(a:topline)

    " if the first line contains only the left delim then just delete it
    if theLine =~ '^[ \t]*' . left . '[ \t]*$' && !g:NERDCompactSexyComs
        call cursor(a:topline, 1)
        normal dd
        let bottomline = bottomline - 1

    " topline contains more than just the left delim
    else

        " remove the delim. If there is a space after it
        " then remove this too if appropriate
        let delimIndx = stridx(theLine, leftUnEsc)
        if strpart(theLine, delimIndx+strlen(leftUnEsc), s:lenSpaceStr) == s:spaceStr && g:NERDSpaceDelims
            let theLine = strpart(theLine, 0, delimIndx) . strpart(theLine, delimIndx+strlen(leftUnEsc)+s:lenSpaceStr)
        else
            let theLine = strpart(theLine, 0, delimIndx) . strpart(theLine, delimIndx+strlen(leftUnEsc))
        endif
        let theLine = s:SwapOutterPlaceHoldersForMultiPartDelims(theLine)
        call setline(a:topline, theLine)
    endif

    " get the last line so we can remove the right delim
    let theLine = getline(bottomline)

    " if the bottomline contains only the right delim then just delete it
    if theLine =~ '^[ \t]*' . right . '[ \t]*$'
        call cursor(bottomline, 1)
        normal dd

    " the last line contains more than the right delim
    else
        " remove the right delim. If there is a space after it and
        " if the appropriate options are set then remove this too.
        let delimIndx = s:LastIndexOfDelim(rightUnEsc, theLine)
        if strpart(theLine, delimIndx+strlen(leftUnEsc), s:lenSpaceStr) == s:spaceStr  && g:NERDSpaceDelims
            let theLine = strpart(theLine, 0, delimIndx) . strpart(theLine, delimIndx+strlen(rightUnEsc)+s:lenSpaceStr)
        else
            let theLine = strpart(theLine, 0, delimIndx) . strpart(theLine, delimIndx+strlen(rightUnEsc))
        endif

        " if the last line also starts with a sexy comment marker then we
        " remove this as well
        if theLine =~ '^[ \t]*' . sexyComMarker

            " remove the sexyComMarker. If there is a space after it then
            " remove that too
            let sexyComMarkerIndx = stridx(theLine, sexyComMarkerUnEsc)
            if strpart(theLine, sexyComMarkerIndx+strlen(sexyComMarkerUnEsc), s:lenSpaceStr) == s:spaceStr  && g:NERDSpaceDelims
                let theLine = strpart(theLine, 0, sexyComMarkerIndx - markerOffset ) . strpart(theLine, sexyComMarkerIndx+strlen(sexyComMarkerUnEsc)+s:lenSpaceStr)
            else
                let theLine = strpart(theLine, 0, sexyComMarkerIndx - markerOffset ) . strpart(theLine, sexyComMarkerIndx+strlen(sexyComMarkerUnEsc))
            endif
        endif

        let theLine = s:SwapOutterPlaceHoldersForMultiPartDelims(theLine)
        call setline(bottomline, theLine)
    endif
endfunction

" Function: s:UncommentLineNormal(line) {{{2
" uncomments the given line and returns the result
" Args:
"   -line: the line to uncomment
function s:UncommentLineNormal(line)
    let line = a:line

    "get the comment status on the line so we know how it is commented
    let lineCommentStatus =  s:IsCommentedOuttermost(b:left, b:right, b:leftAlt, b:rightAlt, line)

    "it is commented with b:left and b:right so remove these delims
    if lineCommentStatus == 1
        let line = s:RemoveDelimiters(b:left, b:right, line)

    "it is commented with b:leftAlt and b:rightAlt so remove these delims
    elseif lineCommentStatus == 2 && g:NERDRemoveAltComs
        let line = s:RemoveDelimiters(b:leftAlt, b:rightAlt, line)

    "it is not properly commented with any delims so we check if it has
    "any random left or right delims on it and remove the outtermost ones
    else
        "get the positions of all delim types on the line
        let indxLeft = s:FindDelimiterIndex(b:left, line)
        let indxLeftAlt = s:FindDelimiterIndex(b:leftAlt, line)
        let indxRight = s:FindDelimiterIndex(b:right, line)
        let indxRightAlt = s:FindDelimiterIndex(b:rightAlt, line)

        "remove the outter most left comment delim
        if indxLeft != -1 && (indxLeft < indxLeftAlt || indxLeftAlt == -1)
            let line = s:RemoveDelimiters(b:left, '', line)
        elseif indxLeftAlt != -1
            let line = s:RemoveDelimiters(b:leftAlt, '', line)
        endif

        "remove the outter most right comment delim
        if indxRight != -1 && (indxRight < indxRightAlt || indxRightAlt == -1)
            let line = s:RemoveDelimiters('', b:right, line)
        elseif indxRightAlt != -1
            let line = s:RemoveDelimiters('', b:rightAlt, line)
        endif
    endif


    let indxLeft = s:FindDelimiterIndex(b:left, line)
    let indxLeftAlt = s:FindDelimiterIndex(b:leftAlt, line)
    let indxLeftPlace = s:FindDelimiterIndex(g:NERDLPlace, line)

    let indxRightPlace = s:FindDelimiterIndex(g:NERDRPlace, line)
    let indxRightAlt = s:FindDelimiterIndex(b:rightAlt, line)
    let indxRightPlace = s:FindDelimiterIndex(g:NERDRPlace, line)

    let right = b:right
    let left = b:left
    if !s:Multipart()
        let right = b:rightAlt
        let left = b:leftAlt
    endif


    "if there are place-holders on the line then we check to see if they are
    "the outtermost delimiters on the line. If so then we replace them with
    "real delimiters
    if indxLeftPlace != -1
        if (indxLeftPlace < indxLeft || indxLeft==-1) && (indxLeftPlace < indxLeftAlt || indxLeftAlt==-1)
            let line = s:ReplaceDelims(g:NERDLPlace, g:NERDRPlace, left, right, line)
        endif
    elseif indxRightPlace != -1
        if (indxRightPlace < indxLeft || indxLeft==-1) && (indxLeftPlace < indxLeftAlt || indxLeftAlt==-1)
            let line = s:ReplaceDelims(g:NERDLPlace, g:NERDRPlace, left, right, line)
        endif

    endif

    let line = s:ConvertLeadingWhiteSpace(line)

    return line
endfunction

" Function: s:UncommentLinesNormal(topline, bottomline) {{{2
" This function is called to uncomment lines that arent a sexy comment
" Args:
"   -topline/bottomline: the top/bottom line numbers of the comment
function s:UncommentLinesNormal(topline, bottomline)
    let currentLine = a:topline
    while currentLine <= a:bottomline
        let line = getline(currentLine)
        call setline(currentLine, s:UncommentLineNormal(line))
        let currentLine = currentLine + 1
    endwhile
endfunction


" Section: Other helper functions {{{1
" ============================================================================

" Function: s:AddLeftDelim(delim, theLine) {{{2
" Args:
function s:AddLeftDelim(delim, theLine)
    return substitute(a:theLine, '^\([ \t]*\)', '\1' . a:delim, '')
endfunction

" Function: s:AddLeftDelimAligned(delim, theLine) {{{2
" Args:
function s:AddLeftDelimAligned(delim, theLine, alignIndx)

    "if the line is not long enough then bung some extra spaces on the front
    "so we can align the delim properly
    let theLine = a:theLine
    if strlen(theLine) < a:alignIndx
        let theLine = strpart(s:spaces, 0, a:alignIndx - strlen(theLine))
    endif

    return strpart(theLine, 0, a:alignIndx) . a:delim . strpart(theLine, a:alignIndx)
endfunction

" Function: s:AddRightDelim(delim, theLine) {{{2
" Args:
function s:AddRightDelim(delim, theLine)
    if a:delim == ''
        return a:theLine
    else
        return substitute(a:theLine, '$', a:delim, '')
    endif
endfunction

" Function: s:AddRightDelimAligned(delim, theLine, alignIndx) {{{2
" Args:
function s:AddRightDelimAligned(delim, theLine, alignIndx)
    if a:delim == ""
        return a:theLine
    else

        " when we align the right delim we are just adding spaces
        " so we get a string containing the needed spaces (it
        " could be empty)
        let extraSpaces = ''
        let extraSpaces = strpart(s:spaces, 0, a:alignIndx-strlen(a:theLine))

        " add the right delim
        return substitute(a:theLine, '$', extraSpaces . a:delim, '')
    endif
endfunction

" Function: s:AltMultipart() {{{2
" returns 1 if the alternative delims are multipart
function s:AltMultipart()
    return b:rightAlt != ''
endfunction

" Function: s:CanCommentLine(forceNested, line) {{{2
"This function is used to determine whether the given line can be commented.
"It returns 1 if it can be and 0 otherwise
"
" Args:
"   -forceNested: a flag indicating whether the caller wants comments to be nested
"    if the current line is already commented
"   -lineNum: the line num of the line to check for commentability
function s:CanCommentLine(forceNested, lineNum)
    let theLine = getline(a:lineNum)

    " make sure we don't comment lines that are just spaces or tabs or empty.
    if theLine =~ "^[ \t]*$"
        return 0
    endif

    "if the line is part of a sexy comment then just flag it...
    if s:IsInSexyComment(a:lineNum)
        return 0
    endif

    let isCommented = s:IsCommentedNormOrSexy(a:lineNum)

    "if the line isnt commented return true
    if !isCommented
        return 1
    endif

    "if the line is commented but nesting is allowed then return true
    if a:forceNested && (!s:Multipart() || g:NERDUsePlaceHolders)
        return 1
    endif

    return 0
endfunction

" Function: s:CanPlaceCursor(line, col) {{{2
" returns 1 if the cursor can be placed exactly in the given position
function s:CanPlaceCursor(line, col)
    let c = col(".")
    let l = line(".")
    call cursor(a:line, a:col)
    let success = (line(".") == a:line && col(".") == a:col)
    call cursor(l,c)
    return success
endfunction

" Function: s:CanSexyCommentLines(topline, bottomline) {{{2
" Return: 1 if the given lines can be commented sexually, 0 otherwise
function s:CanSexyCommentLines(topline, bottomline)
    " see if the selected regions have any sexy comments
    let currentLine = a:topline
    while(currentLine <= a:bottomline)
        if s:IsInSexyComment(currentLine)
            return 0
        endif
        let currentLine = currentLine + 1
    endwhile
    return 1
endfunction
" Function: s:CanToggleCommentLine(forceNested, line) {{{2
"This function is used to determine whether the given line can be toggle commented.
"It returns 1 if it can be and 0 otherwise
"
" Args:
"   -lineNum: the line num of the line to check for commentability
function s:CanToggleCommentLine(forceNested, lineNum)
    let theLine = getline(a:lineNum)
    if (s:IsCommentedFromStartOfLine(b:left, theLine) || s:IsCommentedFromStartOfLine(b:leftAlt, theLine)) && !a:forceNested
        return 0
    endif

    " make sure we don't comment lines that are just spaces or tabs or empty.
    if theLine =~ "^[ \t]*$"
        return 0
    endif

    "if the line is part of a sexy comment then just flag it...
    if s:IsInSexyComment(a:lineNum)
        return 0
    endif

    return 1
endfunction

" Function: s:ConvertLeadingSpacesToTabs(line) {{{2
" This function takes a line and converts all leading tabs on that line into
" spaces
"
" Args:
"   -line: the line whose leading tabs will be converted
function s:ConvertLeadingSpacesToTabs(line)
    let toReturn  = a:line
    while toReturn =~ '^\t*' . s:TabSpace() . '\(.*\)$'
        let toReturn = substitute(toReturn, '^\(\t*\)' . s:TabSpace() . '\(.*\)$'  ,  '\1\t\2' , "")
    endwhile

    return toReturn
endfunction


" Function: s:ConvertLeadingTabsToSpaces(line) {{{2
" This function takes a line and converts all leading spaces on that line into
" tabs
"
" Args:
"   -line: the line whose leading spaces will be converted
function s:ConvertLeadingTabsToSpaces(line)
    let toReturn  = a:line
    while toReturn =~ '^\( *\)\t'
        let toReturn = substitute(toReturn, '^\( *\)\t',  '\1' . s:TabSpace() , "")
    endwhile

    return toReturn
endfunction

" Function: s:ConvertLeadingWhiteSpace(line) {{{2
" Converts the leading white space to tabs/spaces depending on &ts
"
" Args:
"   -line: the line to convert
function s:ConvertLeadingWhiteSpace(line)
    let toReturn = a:line
    while toReturn =~ '^ *\t'
        let toReturn = substitute(toReturn, '^ *\zs\t\ze', s:TabSpace(), "g")
    endwhile

    if !&expandtab
        let toReturn = s:ConvertLeadingSpacesToTabs(toReturn)
    endif

    return toReturn
endfunction


" Function: s:CountNonESCedOccurances(str, searchstr, escChar) {{{2
" This function counts the number of substrings contained in another string.
" These substrings are only counted if they are not escaped with escChar
" Args:
"   -str: the string to look for searchstr in
"   -searchstr: the substring to search for in str
"   -escChar: the escape character which, when preceding an instance of
"    searchstr, will cause it not to be counted
function s:CountNonESCedOccurances(str, searchstr, escChar)
    "get the index of the first occurrence of searchstr
    let indx = stridx(a:str, a:searchstr)

    "if there is an instance of searchstr in str process it
    if indx != -1
        "get the remainder of str after this instance of searchstr is removed
        let lensearchstr = strlen(a:searchstr)
        let strLeft = strpart(a:str, indx+lensearchstr)

        "if this instance of searchstr is not escaped, add one to the count
        "and recurse. If it is escaped, just recurse
        if !s:IsEscaped(a:str, indx, a:escChar)
            return 1 + s:CountNonESCedOccurances(strLeft, a:searchstr, a:escChar)
        else
            return s:CountNonESCedOccurances(strLeft, a:searchstr, a:escChar)
        endif
    endif
endfunction
" Function: s:DoesBlockHaveDelim(delim, top, bottom) {{{2
" Returns 1 if the given block of lines has a delimiter (a:delim) in it
" Args:
"   -delim: the comment delimiter to check the block for
"   -top: the top line number of the block
"   -bottom: the bottom line number of the block
function s:DoesBlockHaveDelim(delim, top, bottom)
    let currentLine = a:top
    while currentLine < a:bottom
        let theline = getline(currentLine)
        if s:FindDelimiterIndex(a:delim, theline) != -1
            return 1
        endif
        let currentLine = currentLine + 1
    endwhile
    return 0
endfunction

" Function: s:DoesBlockHaveMultipartDelim(top, bottom) {{{2
" Returns 1 if the given block has a >= 1 multipart delimiter in it
" Args:
"   -top: the top line number of the block
"   -bottom: the bottom line number of the block
function s:DoesBlockHaveMultipartDelim(top, bottom)
    if s:HasMultipartDelims()
        if s:Multipart()
            return s:DoesBlockHaveDelim(b:left, a:top, a:bottom) || s:DoesBlockHaveDelim(b:right, a:top, a:bottom)
        else
            return s:DoesBlockHaveDelim(b:leftAlt, a:top, a:bottom) || s:DoesBlockHaveDelim(b:rightAlt, a:top, a:bottom)
        endif
    endif
    return 0
endfunction


" Function: s:Esc(str) {{{2
" Escapes all the tricky chars in the given string
function s:Esc(str)
    let charsToEsc = '*/\."&$+'
    return escape(a:str, charsToEsc)
endfunction

" Function: s:FindDelimiterIndex(delimiter, line) {{{2
" This function is used to get the string index of the input comment delimiter
" on the input line. If no valid comment delimiter is found in the line then
" -1 is returned
" Args:
"   -delimiter: the delimiter we are looking to find the index of
"   -line: the line we are looking for delimiter on
function s:FindDelimiterIndex(delimiter, line)

    "make sure the delimiter isnt empty otherwise we go into an infinite loop.
    if a:delimiter == ""
        return -1
    endif


    let l:delimiter = a:delimiter
    let lenDel = strlen(l:delimiter)

    "get the index of the first occurrence of the delimiter
    let delIndx = stridx(a:line, l:delimiter)

    "keep looping thru the line till we either find a real comment delimiter
    "or run off the EOL
    while delIndx != -1

        "if we are not off the EOL get the str before the possible delimiter
        "in question and check if it really is a delimiter. If it is, return
        "its position
        if delIndx != -1
            if s:IsDelimValid(l:delimiter, delIndx, a:line)
                return delIndx
            endif
        endif

        "we have not yet found a real comment delimiter so move past the
        "current one we are lookin at
        let restOfLine = strpart(a:line, delIndx + lenDel)
        let distToNextDelim = stridx(restOfLine , l:delimiter)

        "if distToNextDelim is -1 then there is no more potential delimiters
        "on the line so set delIndx to -1. Otherwise, move along the line by
        "distToNextDelim
        if distToNextDelim == -1
            let delIndx = -1
        else
            let delIndx = delIndx + lenDel + distToNextDelim
        endif
    endwhile

    "there is no comment delimiter on this line
    return -1
endfunction

" Function: s:FindBoundingLinesOfSexyCom(lineNum) {{{2
" This function takes in a line number and tests whether this line number is
" the top/bottom/middle line of a sexy comment. If it is then the top/bottom
" lines of the sexy comment are returned
" Args:
"   -lineNum: the line number that is to be tested whether it is the
"    top/bottom/middle line of a sexy com
" Returns:
"   A string that has the top/bottom lines of the sexy comment encoded in it.
"   The format is 'topline,bottomline'. If a:lineNum turns out not to be the
"   top/bottom/middle of a sexy comment then -1 is returned
function s:FindBoundingLinesOfSexyCom(lineNum)

    "find which delimiters to look for as the start/end delims of the comment
    let left = ''
    let right = ''
    if s:Multipart()
        let left = s:GetLeft(0,0,1)
        let right = s:GetRight(0,0,1)
    elseif s:AltMultipart()
        let left = s:GetLeft(1,0,1)
        let right = s:GetRight(1,0,1)
    else
        return []
    endif

    let sexyComMarker = s:GetSexyComMarker(0, 1)

    "initialise the top/bottom line numbers of the sexy comment to -1
    let top = -1
    let bottom = -1

    let currentLine = a:lineNum
    while top == -1 || bottom == -1
        let theLine = getline(currentLine)

        "check if the current line is the top of the sexy comment
        if currentLine <= a:lineNum && theLine =~ '^[ \t]*' . left && theLine !~ '.*' . right && currentLine < s:NumLinesInBuf()
            let top = currentLine
            let currentLine = a:lineNum

        "check if the current line is the bottom of the sexy comment
        elseif theLine =~ '^[ \t]*' . right && theLine !~ '.*' . left && currentLine > 1
            let bottom = currentLine

        "the right delimiter is on the same line as the last sexyComMarker
        elseif theLine =~ '^[ \t]*' . sexyComMarker . '.*' . right
            let bottom = currentLine

        "we have not found the top or bottom line so we assume currentLine is an
        "intermediate line and look to prove otherwise
        else

            "if the line doesnt start with a sexyComMarker then it is not a sexy
            "comment
            if theLine !~ '^[ \t]*' . sexyComMarker
                return []
            endif

        endif

        "if top is -1 then we havent found the top yet so keep looking up
        if top == -1
            let currentLine = currentLine - 1
        "if we have found the top line then go down looking for the bottom
        else
            let currentLine = currentLine + 1
        endif

    endwhile

    return [top, bottom]
endfunction


" Function: s:GetLeft(alt, space, esc) {{{2
" returns the left/left-alternative delimiter
" Args:
"   -alt: specifies whether to get left or left-alternative delim
"   -space: specifies whether the delim should be spaced or not
"    (the space string will only be added if NERDSpaceDelims is set)
"   -esc: specifies whether the tricky chars in the delim should be ESCed
function s:GetLeft(alt, space, esc)
    let delim = b:left

    if a:alt
        if b:leftAlt == ''
            return ''
        else
            let delim = b:leftAlt
        endif
    endif
    if delim == ''
        return ''
    endif

    if a:space && g:NERDSpaceDelims
        let delim = delim . s:spaceStr
    endif

    if a:esc
        let delim = s:Esc(delim)
    endif

    return delim
endfunction

" Function: s:GetRight(alt, space, esc) {{{2
" returns the right/right-alternative delimiter
" Args:
"   -alt: specifies whether to get right or right-alternative delim
"   -space: specifies whether the delim should be spaced or not
"   (the space string will only be added if NERDSpaceDelims is set)
"   -esc: specifies whether the tricky chars in the delim should be ESCed
function s:GetRight(alt, space, esc)
    let delim = b:right

    if a:alt
        if !s:AltMultipart()
            return ''
        else
            let delim = b:rightAlt
        endif
    endif
    if delim == ''
        return ''
    endif

    if a:space && g:NERDSpaceDelims
        let delim = s:spaceStr . delim
    endif

    if a:esc
        let delim = s:Esc(delim)
    endif

    return delim
endfunction


" Function: s:GetSexyComMarker() {{{2
" Returns the sexy comment marker for the current filetype.
"
" C style sexy comments are assumed if possible. If not then the sexy comment
" marker is the last char of the delimiter pair that has both left and right
" delims and has the longest left delim
"
" Args:
"   -space: specifies whether the marker is to have a space string after it
"    (the space string will only be added if NERDSpaceDelims is set)
"   -esc: specifies whether the tricky chars in the marker are to be ESCed
function s:GetSexyComMarker(space, esc)
    let sexyComMarker = b:sexyComMarker

    "if there is no hardcoded marker then we find one
    if sexyComMarker == ''

        "if the filetype has c style comments then use standard c sexy
        "comments
        if s:HasCStyleComments()
            let sexyComMarker = '*'
        else
            "find a comment marker by getting the longest available left delim
            "(that has a corresponding right delim) and taking the last char
            let lenLeft = strlen(b:left)
            let lenLeftAlt = strlen(b:leftAlt)
            let left = ''
            let right = ''
            if s:Multipart() && lenLeft >= lenLeftAlt
                let left = b:left
            elseif s:AltMultipart()
                let left = b:leftAlt
            else
                return -1
            endif

            "get the last char of left
            let sexyComMarker = strpart(left, strlen(left)-1)
        endif
    endif

    if a:space && g:NERDSpaceDelims
        let sexyComMarker = sexyComMarker . s:spaceStr
    endif

    if a:esc
        let sexyComMarker = s:Esc(sexyComMarker)
    endif

    return sexyComMarker
endfunction

" Function: s:GetSexyComLeft(space, esc) {{{2
" Returns the left delimiter for sexy comments for this filetype or -1 if
" there is none. C style sexy comments are used if possible
" Args:
"   -space: specifies if the delim has a space string on the end
"   (the space string will only be added if NERDSpaceDelims is set)
"   -esc: specifies whether the tricky chars in the string are ESCed
function s:GetSexyComLeft(space, esc)
    let lenLeft = strlen(b:left)
    let lenLeftAlt = strlen(b:leftAlt)
    let left = ''

    "assume c style sexy comments if possible
    if s:HasCStyleComments()
        let left = '/*'
    else
        "grab the longest left delim that has a right
        if s:Multipart() && lenLeft >= lenLeftAlt
            let left = b:left
        elseif s:AltMultipart()
            let left = b:leftAlt
        else
            return -1
        endif
    endif

    if a:space && g:NERDSpaceDelims
        let left = left . s:spaceStr
    endif

    if a:esc
        let left = s:Esc(left)
    endif

    return left
endfunction

" Function: s:GetSexyComRight(space, esc) {{{2
" Returns the right delimiter for sexy comments for this filetype or -1 if
" there is none. C style sexy comments are used if possible.
" Args:
"   -space: specifies if the delim has a space string on the start
"   (the space string will only be added if NERDSpaceDelims
"   is specified for the current filetype)
"   -esc: specifies whether the tricky chars in the string are ESCed
function s:GetSexyComRight(space, esc)
    let lenLeft = strlen(b:left)
    let lenLeftAlt = strlen(b:leftAlt)
    let right = ''

    "assume c style sexy comments if possible
    if s:HasCStyleComments()
        let right = '*/'
    else
        "grab the right delim that pairs with the longest left delim
        if s:Multipart() && lenLeft >= lenLeftAlt
            let right = b:right
        elseif s:AltMultipart()
            let right = b:rightAlt
        else
            return -1
        endif
    endif

    if a:space && g:NERDSpaceDelims
        let right = s:spaceStr . right
    endif

    if a:esc
        let right = s:Esc(right)
    endif

    return right
endfunction

" Function: s:HasMultipartDelims() {{{2
" Returns 1 iff the current filetype has at least one set of multipart delims
function s:HasMultipartDelims()
    return s:Multipart() || s:AltMultipart()
endfunction

" Function: s:HasLeadingTabs(...) {{{2
" Returns 1 if any of the given strings have leading tabs
function s:HasLeadingTabs(...)
    for s in a:000
        if s =~ '^\t.*'
            return 1
        end
    endfor
    return 0
endfunction
" Function: s:HasCStyleComments() {{{2
" Returns 1 iff the current filetype has c style comment delimiters
function s:HasCStyleComments()
    return (b:left == '/*' && b:right == '*/') || (b:leftAlt == '/*' && b:rightAlt == '*/')
endfunction

" Function: s:IsCommentedNormOrSexy(lineNum) {{{2
"This function is used to determine whether the given line is commented with
"either set of delimiters or if it is part of a sexy comment
"
" Args:
"   -lineNum: the line number of the line to check
function s:IsCommentedNormOrSexy(lineNum)
    let theLine = getline(a:lineNum)

    "if the line is commented normally return 1
    if s:IsCommented(b:left, b:right, theLine) || s:IsCommented(b:leftAlt, b:rightAlt, theLine)
        return 1
    endif

    "if the line is part of a sexy comment return 1
    if s:IsInSexyComment(a:lineNum)
        return 1
    endif
    return 0
endfunction

" Function: s:IsCommented(left, right, line) {{{2
"This function is used to determine whether the given line is commented with
"the given delimiters
"
" Args:
"   -line: the line that to check if commented
"   -left/right: the left and right delimiters to check for
function s:IsCommented(left, right, line)
    "if the line isnt commented return true
    if s:FindDelimiterIndex(a:left, a:line) != -1 && (s:FindDelimiterIndex(a:right, a:line) != -1 || !s:Multipart())
        return 1
    endif
    return 0
endfunction

" Function: s:IsCommentedFromStartOfLine(left, line) {{{2
"This function is used to determine whether the given line is commented with
"the given delimiters at the start of the line i.e the left delimiter is the
"first thing on the line (apart from spaces\tabs)
"
" Args:
"   -line: the line that to check if commented
"   -left: the left delimiter to check for
function s:IsCommentedFromStartOfLine(left, line)
    let theLine = s:ConvertLeadingTabsToSpaces(a:line)
    let numSpaces = strlen(substitute(theLine, '^\( *\).*$', '\1', ''))
    let delimIndx = s:FindDelimiterIndex(a:left, theLine)
    return delimIndx == numSpaces
endfunction

" Function: s:IsCommentedOuttermost(left, right, leftAlt, rightAlt, line) {{{2
" Finds the type of the outtermost delims on the line
"
" Args:
"   -line: the line that to check if the outtermost comments on it are
"    left/right
"   -left/right: the left and right delimiters to check for
"   -leftAlt/rightAlt: the left and right alternative delimiters to check for
"
" Returns:
"   0 if the line is not commented with either set of delims
"   1 if the line is commented with the left/right delim set
"   2 if the line is commented with the leftAlt/rightAlt delim set
function s:IsCommentedOuttermost(left, right, leftAlt, rightAlt, line)
    "get the first positions of the left delims and the last positions of the
    "right delims
    let indxLeft = s:FindDelimiterIndex(a:left, a:line)
    let indxLeftAlt = s:FindDelimiterIndex(a:leftAlt, a:line)
    let indxRight = s:LastIndexOfDelim(a:right, a:line)
    let indxRightAlt = s:LastIndexOfDelim(a:rightAlt, a:line)

    "check if the line has a left delim before a leftAlt delim
    if (indxLeft <= indxLeftAlt || indxLeftAlt == -1) && indxLeft != -1
        "check if the line has a right delim after any rightAlt delim
        if (indxRight > indxRightAlt && indxRight > indxLeft) || !s:Multipart()
            return 1
        endif

        "check if the line has a leftAlt delim before a left delim
    elseif (indxLeftAlt <= indxLeft || indxLeft == -1) && indxLeftAlt != -1
        "check if the line has a rightAlt delim after any right delim
        if (indxRightAlt > indxRight && indxRightAlt > indxLeftAlt) || !s:AltMultipart()
            return 2
        endif
    else
        return 0
    endif

    return 0

endfunction


" Function: s:IsDelimValid(delimiter, delIndx, line) {{{2
" This function is responsible for determining whether a given instance of a
" comment delimiter is a real delimiter or not. For example, in java the
" // string is a comment delimiter but in the line:
"               System.out.println("//");
" it does not count as a comment delimiter. This function is responsible for
" distinguishing between such cases. It does so by applying a set of
" heuristics that are not fool proof but should work most of the time.
"
" Args:
"   -delimiter: the delimiter we are validating
"   -delIndx: the position of delimiter in line
"   -line: the line that delimiter occurs in
"
" Returns:
" 0 if the given delimiter is not a real delimiter (as far as we can tell) ,
" 1 otherwise
function s:IsDelimValid(delimiter, delIndx, line)
    "get the delimiter without the escchars
    let l:delimiter = a:delimiter

    "get the strings before and after the delimiter
    let preComStr = strpart(a:line, 0, a:delIndx)
    let postComStr = strpart(a:line, a:delIndx+strlen(delimiter))

    "to check if the delimiter is real, make sure it isnt preceded by
    "an odd number of quotes and followed by the same (which would indicate
    "that it is part of a string and therefore is not a comment)
    if !s:IsNumEven(s:CountNonESCedOccurances(preComStr, '"', "\\")) && !s:IsNumEven(s:CountNonESCedOccurances(postComStr, '"', "\\"))
        return 0
    endif
    if !s:IsNumEven(s:CountNonESCedOccurances(preComStr, "'", "\\")) && !s:IsNumEven(s:CountNonESCedOccurances(postComStr, "'", "\\"))
        return 0
    endif
    if !s:IsNumEven(s:CountNonESCedOccurances(preComStr, "`", "\\")) && !s:IsNumEven(s:CountNonESCedOccurances(postComStr, "`", "\\"))
        return 0
    endif


    "if the comment delimiter is escaped, assume it isnt a real delimiter
    if s:IsEscaped(a:line, a:delIndx, "\\")
        return 0
    endif

    "vim comments are so fuckin stupid!! Why the hell do they have comment
    "delimiters that are used elsewhere in the syntax?!?! We need to check
    "some conditions especially for vim
    if &filetype == "vim"
        if !s:IsNumEven(s:CountNonESCedOccurances(preComStr, '"', "\\"))
            return 0
        endif

        "if the delimiter is on the very first char of the line or is the
        "first non-tab/space char on the line then it is a valid comment delimiter
        if a:delIndx == 0 || a:line =~ "^[ \t]\\{" . a:delIndx . "\\}\".*$"
            return 1
        endif

        let numLeftParen =s:CountNonESCedOccurances(preComStr, "(", "\\")
        let numRightParen =s:CountNonESCedOccurances(preComStr, ")", "\\")

        "if the quote is inside brackets then assume it isnt a comment
        if numLeftParen > numRightParen
            return 0
        endif

        "if the line has an even num of unescaped "'s then we can assume that
        "any given " is not a comment delimiter
        if s:IsNumEven(s:CountNonESCedOccurances(a:line, "\"", "\\"))
            return 0
        endif
    endif

    return 1

endfunction

" Function: s:IsNumEven(num) {{{2
" A small function the returns 1 if the input number is even and 0 otherwise
" Args:
"   -num: the number to check
function s:IsNumEven(num)
    return (a:num % 2) == 0
endfunction

" Function: s:IsEscaped(str, indx, escChar) {{{2
" This function takes a string, an index into that string and an esc char and
" returns 1 if the char at the index is escaped (i.e if it is preceded by an
" odd number of esc chars)
" Args:
"   -str: the string to check
"   -indx: the index into str that we want to check
"   -escChar: the escape char the char at indx may be ESCed with
function s:IsEscaped(str, indx, escChar)
    "initialise numEscChars to 0 and look at the char before indx
    let numEscChars = 0
    let curIndx = a:indx-1

    "keep going back thru str until we either reach the start of the str or
    "run out of esc chars
    while curIndx >= 0 && strpart(a:str, curIndx, 1) == a:escChar

        "we have found another esc char so add one to the count and move left
        "one char
        let numEscChars  = numEscChars + 1
        let curIndx = curIndx - 1

    endwhile

    "if there is an odd num of esc chars directly before the char at indx then
    "the char at indx is escaped
    return !s:IsNumEven(numEscChars)
endfunction

" Function: s:IsInSexyComment(line) {{{2
" returns 1 if the given line number is part of a sexy comment
function s:IsInSexyComment(line)
    return !empty(s:FindBoundingLinesOfSexyCom(a:line))
endfunction

" Function: s:IsSexyComment(topline, bottomline) {{{2
" This function takes in 2 line numbers and returns 1 if the lines between and
" including the given line numbers are a sexy comment. It returns 0 otherwise.
" Args:
"   -topline: the line that the possible sexy comment starts on
"   -bottomline: the line that the possible sexy comment stops on
function s:IsSexyComment(topline, bottomline)

    "get the delim set that would be used for a sexy comment
    let left = ''
    let right = ''
    if s:Multipart()
        let left = b:left
        let right = b:right
    elseif s:AltMultipart()
        let left = b:leftAlt
        let right = b:rightAlt
    else
        return 0
    endif

    "swap the top and bottom line numbers around if need be
    let topline = a:topline
    let bottomline = a:bottomline
    if bottomline < topline
        topline = bottomline
        bottomline = a:topline
    endif

    "if there is < 2 lines in the comment it cannot be sexy
    if (bottomline - topline) <= 0
        return 0
    endif

    "if the top line doesnt begin with a left delim then the comment isnt sexy
    if getline(a:topline) !~ '^[ \t]*' . left
        return 0
    endif

    "if there is a right delim on the top line then this isnt a sexy comment
    if s:FindDelimiterIndex(right, getline(a:topline)) != -1
        return 0
    endif

    "if there is a left delim on the bottom line then this isnt a sexy comment
    if s:FindDelimiterIndex(left, getline(a:bottomline)) != -1
        return 0
    endif

    "if the bottom line doesnt begin with a right delim then the comment isnt
    "sexy
    if getline(a:bottomline) !~ '^.*' . right . '$'
        return 0
    endif

    let sexyComMarker = s:GetSexyComMarker(0, 1)

    "check each of the intermediate lines to make sure they start with a
    "sexyComMarker
    let currentLine = a:topline+1
    while currentLine < a:bottomline
        let theLine = getline(currentLine)

        if theLine !~ '^[ \t]*' . sexyComMarker
            return 0
        endif

        "if there is a right delim in an intermediate line then the block isnt
        "a sexy comment
        if s:FindDelimiterIndex(right, theLine) != -1
            return 0
        endif

        let currentLine = currentLine + 1
    endwhile

    "we have not found anything to suggest that this isnt a sexy comment so
    return 1

endfunction

" Function: s:LastIndexOfDelim(delim, str) {{{2
" This function takes a string and a delimiter and returns the last index of
" that delimiter in string
" Args:
"   -delim: the delimiter to look for
"   -str: the string to look for delim in
function s:LastIndexOfDelim(delim, str)
    let delim = a:delim
    let lenDelim = strlen(delim)

    "set index to the first occurrence of delim. If there is no occurrence then
    "bail
    let indx = s:FindDelimiterIndex(delim, a:str)
    if indx == -1
        return -1
    endif

    "keep moving to the next instance of delim in str till there is none left
    while 1

        "search for the next delim after the previous one
        let searchStr = strpart(a:str, indx+lenDelim)
        let indx2 = s:FindDelimiterIndex(delim, searchStr)

        "if we find a delim update indx to record the position of it, if we
        "dont find another delim then indx is the last one so break out of
        "this loop
        if indx2 != -1
            let indx = indx + indx2 + lenDelim
        else
            break
        endif
    endwhile

    return indx

endfunction

" Function: s:LeftMostIndx(countCommentedLines, countEmptyLines, topline, bottomline) {{{2
" This function takes in 2 line numbers and returns the index of the left most
" char (that is not a space or a tab) on all of these lines.
" Args:
"   -countCommentedLines: 1 if lines that are commented are to be checked as
"    well. 0 otherwise
"   -countEmptyLines: 1 if empty lines are to be counted in the search
"   -topline: the top line to be checked
"   -bottomline: the bottom line to be checked
function s:LeftMostIndx(countCommentedLines, countEmptyLines, topline, bottomline)

    " declare the left most index as an extreme value
    let leftMostIndx = 1000

    " go thru the block line by line updating leftMostIndx
    let currentLine = a:topline
    while currentLine <= a:bottomline

        " get the next line and if it is allowed to be commented, or is not
        " commented, check it
        let theLine = getline(currentLine)
        if a:countEmptyLines || theLine !~ '^[ \t]*$'
            if a:countCommentedLines || (!s:IsCommented(b:left, b:right, theLine) && !s:IsCommented(b:leftAlt, b:rightAlt, theLine))
                " convert spaces to tabs and get the number of leading spaces for
                " this line and update leftMostIndx if need be
                let theLine = s:ConvertLeadingTabsToSpaces(theLine)
                let leadSpaceOfLine = strlen( substitute(theLine, '\(^[ \t]*\).*$','\1','') )
                if leadSpaceOfLine < leftMostIndx
                    let leftMostIndx = leadSpaceOfLine
                endif
            endif
        endif

        " move on to the next line
        let currentLine = currentLine + 1
    endwhile

    if leftMostIndx == 1000
        return 0
    else
        return leftMostIndx
    endif
endfunction

" Function: s:Multipart() {{{2
" returns 1 if the current delims are multipart
function s:Multipart()
    return b:right != ''
endfunction

" Function: s:NerdEcho(msg, typeOfMsg) {{{2
" Args:
"   -msg: the message to echo
"   -typeOfMsg: 0 = warning message
"               1 = normal message
function s:NerdEcho(msg, typeOfMsg)
    if a:typeOfMsg == 0
        echohl WarningMsg
        echo 'NERDCommenter:' . a:msg
        echohl None
    elseif a:typeOfMsg == 1
        echo 'NERDCommenter:' . a:msg
    endif
endfunction

" Function: s:NumberOfLeadingTabs(s) {{{2
" returns the number of leading tabs in the given string
function s:NumberOfLeadingTabs(s)
    return strlen(substitute(a:s, '^\(\t*\).*$', '\1', ""))
endfunction

" Function: s:NumLinesInBuf() {{{2
" Returns the number of lines in the current buffer
function s:NumLinesInBuf()
    return line('$')
endfunction

" Function: s:ReplaceDelims(toReplace1, toReplace2, replacor1, replacor2, str) {{{2
" This function takes in a string, 2 delimiters in that string and 2 strings
" to replace these delimiters with.
"
" Args:
"   -toReplace1: the first delimiter to replace
"   -toReplace2: the second delimiter to replace
"   -replacor1: the string to replace toReplace1 with
"   -replacor2: the string to replace toReplace2 with
"   -str: the string that the delimiters to be replaced are in
function s:ReplaceDelims(toReplace1, toReplace2, replacor1, replacor2, str)
    let line = s:ReplaceLeftMostDelim(a:toReplace1, a:replacor1, a:str)
    let line = s:ReplaceRightMostDelim(a:toReplace2, a:replacor2, line)
    return line
endfunction

" Function: s:ReplaceLeftMostDelim(toReplace, replacor, str) {{{2
" This function takes a string and a delimiter and replaces the left most
" occurrence of this delimiter in the string with a given string
"
" Args:
"   -toReplace: the delimiter in str that is to be replaced
"   -replacor: the string to replace toReplace with
"   -str: the string that contains toReplace
function s:ReplaceLeftMostDelim(toReplace, replacor, str)
    let toReplace = a:toReplace
    let replacor = a:replacor
    "get the left most occurrence of toReplace
    let indxToReplace = s:FindDelimiterIndex(toReplace, a:str)

    "if there IS an occurrence of toReplace in str then replace it and return
    "the resulting string
    if indxToReplace != -1
        let line = strpart(a:str, 0, indxToReplace) . replacor . strpart(a:str, indxToReplace+strlen(toReplace))
        return line
    endif

    return a:str
endfunction

" Function: s:ReplaceRightMostDelim(toReplace, replacor, str) {{{2
" This function takes a string and a delimiter and replaces the right most
" occurrence of this delimiter in the string with a given string
"
" Args:
"   -toReplace: the delimiter in str that is to be replaced
"   -replacor: the string to replace toReplace with
"   -str: the string that contains toReplace
"
function s:ReplaceRightMostDelim(toReplace, replacor, str)
    let toReplace = a:toReplace
    let replacor = a:replacor
    let lenToReplace = strlen(toReplace)

    "get the index of the last delim in str
    let indxToReplace = s:LastIndexOfDelim(toReplace, a:str)

    "if there IS a delimiter in str, replace it and return the result
    let line = a:str
    if indxToReplace != -1
        let line = strpart(a:str, 0, indxToReplace) . replacor . strpart(a:str, indxToReplace+strlen(toReplace))
    endif
    return line
endfunction

"FUNCTION: s:RestoreScreenState() {{{2
"
"Sets the screen state back to what it was when s:SaveScreenState was last
"called.
"
function s:RestoreScreenState()
    if !exists("t:NERDComOldTopLine") || !exists("t:NERDComOldPos")
        throw 'NERDCommenter exception: cannot restore screen'
    endif

    call cursor(t:NERDComOldTopLine, 0)
    normal zt
    call setpos(".", t:NERDComOldPos)
endfunction

" Function: s:RightMostIndx(countCommentedLines, countEmptyLines, topline, bottomline) {{{2
" This function takes in 2 line numbers and returns the index of the right most
" char on all of these lines.
" Args:
"   -countCommentedLines: 1 if lines that are commented are to be checked as
"    well. 0 otherwise
"   -countEmptyLines: 1 if empty lines are to be counted in the search
"   -topline: the top line to be checked
"   -bottomline: the bottom line to be checked
function s:RightMostIndx(countCommentedLines, countEmptyLines, topline, bottomline)
    let rightMostIndx = -1

    " go thru the block line by line updating rightMostIndx
    let currentLine = a:topline
    while currentLine <= a:bottomline

        " get the next line and see if it is commentable, otherwise it doesnt
        " count
        let theLine = getline(currentLine)
        if a:countEmptyLines || theLine !~ '^[ \t]*$'

            if a:countCommentedLines || (!s:IsCommented(b:left, b:right, theLine) && !s:IsCommented(b:leftAlt, b:rightAlt, theLine))

                " update rightMostIndx if need be
                let theLine = s:ConvertLeadingTabsToSpaces(theLine)
                let lineLen = strlen(theLine)
                if lineLen > rightMostIndx
                    let rightMostIndx = lineLen
                endif
            endif
        endif

        " move on to the next line
        let currentLine = currentLine + 1
    endwhile

    return rightMostIndx
endfunction

"FUNCTION: s:SaveScreenState() {{{2
"Saves the current cursor position in the current buffer and the window
"scroll position
function s:SaveScreenState()
    let t:NERDComOldPos = getpos(".")
    let t:NERDComOldTopLine = line("w0")
endfunction

" Function: s:SwapOutterMultiPartDelimsForPlaceHolders(line) {{{2
" This function takes a line and swaps the outter most multi-part delims for
" place holders
" Args:
"   -line: the line to swap the delims in
"
function s:SwapOutterMultiPartDelimsForPlaceHolders(line)
    " find out if the line is commented using normal delims and/or
    " alternate ones
    let isCommented = s:IsCommented(b:left, b:right, a:line)
    let isCommentedAlt = s:IsCommented(b:leftAlt, b:rightAlt, a:line)

    let line2 = a:line

    "if the line is commented and there is a right delimiter, replace
    "the delims with place-holders
    if isCommented && s:Multipart()
        let line2 = s:ReplaceDelims(b:left, b:right, g:NERDLPlace, g:NERDRPlace, a:line)

    "similarly if the line is commented with the alternative
    "delimiters
    elseif isCommentedAlt && s:AltMultipart()
        let line2 = s:ReplaceDelims(b:leftAlt, b:rightAlt, g:NERDLPlace, g:NERDRPlace, a:line)
    endif

    return line2
endfunction

" Function: s:SwapOutterPlaceHoldersForMultiPartDelims(line) {{{2
" This function takes a line and swaps the outtermost place holders for
" multi-part delims
" Args:
"   -line: the line to swap the delims in
"
function s:SwapOutterPlaceHoldersForMultiPartDelims(line)
    let left = ''
    let right = ''
    if s:Multipart()
        let left = b:left
        let right = b:right
    elseif s:AltMultipart()
        let left = b:leftAlt
        let right = b:rightAlt
    endif

    let line = s:ReplaceDelims(g:NERDLPlace, g:NERDRPlace, left, right, a:line)
    return line
endfunction
" Function: s:TabbedCol(line, col) {{{2
" Gets the col number for given line and existing col number. The new col
" number is the col number when all leading spaces are converted to tabs
" Args:
"   -line:the line to get the rel col for
"   -col: the abs col
function s:TabbedCol(line, col)
    let lineTruncated = strpart(a:line, 0, a:col)
    let lineSpacesToTabs = substitute(lineTruncated, s:TabSpace(), '\t', 'g')
    return strlen(lineSpacesToTabs)
endfunction
"FUNCTION: s:TabSpace() {{{2
"returns a string of spaces equal in length to &tabstop
function s:TabSpace()
    let tabSpace = ""
    let spacesPerTab = &tabstop
    while spacesPerTab > 0
        let tabSpace = tabSpace . " "
        let spacesPerTab = spacesPerTab - 1
    endwhile
    return tabSpace
endfunction

" Function: s:UnEsc(str, escChar) {{{2
" This function removes all the escape chars from a string
" Args:
"   -str: the string to remove esc chars from
"   -escChar: the escape char to be removed
function s:UnEsc(str, escChar)
    return substitute(a:str, a:escChar, "", "g")
endfunction

" Function: s:UntabbedCol(line, col) {{{2
" Takes a line and a col and returns the absolute column of col taking into
" account that a tab is worth 3 or 4 (or whatever) spaces.
" Args:
"   -line:the line to get the abs col for
"   -col: the col that doesnt take into account tabs
function s:UntabbedCol(line, col)
    let lineTruncated = strpart(a:line, 0, a:col)
    let lineTabsToSpaces = substitute(lineTruncated, '\t', s:TabSpace(), 'g')
    return strlen(lineTabsToSpaces)
endfunction
" Section: Comment mapping setup {{{1
" ===========================================================================
" This is where the mappings calls are made that set up the commenting key
" mappings.

" set up the mapping to switch to/from alternative delimiters
execute 'nnoremap <silent>' . g:NERDAltComMap . ' :call <SID>SwitchToAlternativeDelimiters(1)<cr>'

" set up the mappings to comment out lines
execute 'nnoremap <silent>' . g:NERDComLineMap . ' :call NERDComment(0, "norm")<cr>'
execute 'vnoremap <silent>' . g:NERDComLineMap . ' <ESC>:call NERDComment(1, "norm")<cr>'

" set up the mappings to do toggle comments
execute 'nnoremap <silent>' . g:NERDComLineToggleMap . ' :call NERDComment(0, "toggle")<cr>'
execute 'vnoremap <silent>' . g:NERDComLineToggleMap . ' <ESC>:call NERDComment(1, "toggle")<cr>'

" set up the mapp to do minimal comments
execute 'nnoremap <silent>' . g:NERDComLineMinimalMap . ' :call NERDComment(0, "minimal")<cr>'
execute 'vnoremap <silent>' . g:NERDComLineMinimalMap . ' <ESC>:call NERDComment(1, "minimal")<cr>'

" set up the mappings to comment out lines sexily
execute 'nnoremap <silent>' . g:NERDComLineSexyMap . ' :call NERDComment(0, "sexy")<CR>'
execute 'vnoremap <silent>' . g:NERDComLineSexyMap . ' <ESC>:call NERDComment(1, "sexy")<CR>'

" set up the mappings to do invert comments
execute 'nnoremap <silent>' . g:NERDComLineInvertMap . ' :call NERDComment(0, "invert")<CR>'
execute 'vnoremap <silent>' . g:NERDComLineInvertMap . ' <ESC>:call NERDComment(1, "invert")<CR>'

" set up the mappings to yank then comment out lines
execute 'nmap <silent>' . g:NERDComLineYankMap . ' :call NERDComment(0, "yank")<CR>'
execute 'vmap <silent>' . g:NERDComLineYankMap . ' <ESC>:call NERDComment(1, "yank")<CR>'

" set up the mappings for left aligned comments
execute 'nnoremap <silent>' . g:NERDComAlignLeftMap . ' :call NERDComment(0, "alignLeft")<cr>'
execute 'vnoremap <silent>' . g:NERDComAlignLeftMap . ' <ESC>:call NERDComment(1, "alignLeft")<cr>'

" set up the mappings for right aligned comments
execute 'nnoremap <silent>' . g:NERDComAlignRightMap . ' :call NERDComment(0, "alignRight")<cr>'
execute 'vnoremap <silent>' . g:NERDComAlignRightMap . ' <ESC>:call NERDComment(1, "alignRight")<cr>'

" set up the mappings for left and right aligned comments
execute 'nnoremap <silent>' . g:NERDComAlignBothMap . ' :call NERDComment(0, "alignBoth")<cr>'
execute 'vnoremap <silent>' . g:NERDComAlignBothMap . ' <ESC>:call NERDComment(1, "alignBoth")<cr>'

" set up the mappings to do nested comments
execute 'nnoremap <silent>' . g:NERDComLineNestMap . ' :call NERDComment(0, "nested")<cr>'
execute 'vnoremap <silent>' . g:NERDComLineNestMap . ' <ESC>:call NERDComment(1, "nested")<cr>'

" set up the mapping to uncomment a line
execute 'nnoremap <silent>' . g:NERDUncomLineMap . ' :call NERDComment(0, "uncomment")<cr>'
execute 'vnoremap <silent>' . g:NERDUncomLineMap . ' :call NERDComment(1, "uncomment")<cr>'

" set up the mapping to comment out to the end of the line
execute 'nnoremap <silent>' . g:NERDComToEOLMap . ' :call NERDComment(0, "toEOL")<cr>'

" set up the mappings to append comments to the line
execute 'nmap <silent>' . g:NERDAppendComMap . ' :call NERDComment(0, "append")<cr>'

" set up the mappings to append comments to the line
execute 'nmap <silent>' . g:NERDPrependComMap . ' :call NERDComment(0, "prepend")<cr>'

" set up the mapping to insert comment delims at the cursor position in insert mode
execute 'inoremap <silent>' . g:NERDComInInsertMap . ' ' . '<SPACE><BS><ESC>:call NERDComment(0, "insert")<CR>'

" Section: Menu item setup {{{1
" ===========================================================================
"check if the user wants the menu to be displayed
if g:NERDMenuMode != 0

    let menuRoot = ""
    if g:NERDMenuMode == 1
        let menuRoot = 'comment'
    elseif g:NERDMenuMode == 2
        let menuRoot = '&comment'
    elseif g:NERDMenuMode == 3
        let menuRoot = '&Plugin.&comment'
    endif

    execute 'nmenu <silent> '. menuRoot .'.Comment<TAB>' . escape(g:NERDComLineMap, '\') . ' :call NERDComment(0, "norm")<CR>'
    execute 'vmenu <silent> '. menuRoot .'.Comment<TAB>' . escape(g:NERDComLineMap, '\') . ' <ESC>:call NERDComment(1, "norm")<CR>'

    execute 'nmenu <silent> '. menuRoot .'.Comment\ Toggle<TAB>' . escape(g:NERDComLineToggleMap, '\') . ' :call NERDComment(0, "toggle")<CR>'
    execute 'vmenu <silent> '. menuRoot .'.Comment\ Toggle<TAB>' . escape(g:NERDComLineToggleMap, '\') . ' <ESC>:call NERDComment(1, "toggle")<CR>'

    execute 'nmenu <silent> '. menuRoot .'.Comment\ Minimal<TAB>' . escape(g:NERDComLineMinimalMap, '\') . ' :call NERDComment(0, "minimal")<CR>'
    execute 'vmenu <silent> '. menuRoot .'.Comment\ Minimal<TAB>' . escape(g:NERDComLineMinimalMap, '\') . ' <ESC>:call NERDComment(1, "minimal")<CR>'

    execute 'nmenu <silent> '. menuRoot .'.Comment\ Nested<TAB>' . escape(g:NERDComLineNestMap, '\') . ' :call NERDComment(0, "nested")<CR>'
    execute 'vmenu <silent> '. menuRoot .'.Comment\ Nested<TAB>' . escape(g:NERDComLineNestMap, '\') . ' <ESC>:call NERDComment(1, "nested")<CR>'

    execute 'nmenu <silent> '. menuRoot .'.Comment\ To\ EOL<TAB>' . escape(g:NERDComToEOLMap, '\') . ' :call NERDComment(0, "toEOL")<cr>'

    execute 'nmenu <silent> '. menuRoot .'.Comment\ Invert<TAB>' . escape(g:NERDComLineInvertMap, '\') . ' :call NERDComment(0,"invert")<CR>'
    execute 'vmenu <silent> '. menuRoot .'.Comment\ Invert<TAB>' . escape(g:NERDComLineInvertMap, '\') . ' <ESC>:call NERDComment(1,"invert")<CR>'

    execute 'nmenu <silent> '. menuRoot .'.Comment\ Sexily<TAB>' . escape(g:NERDComLineSexyMap, '\') . ' :call NERDComment(0,"sexy")<CR>'
    execute 'vmenu <silent> '. menuRoot .'.Comment\ Sexily<TAB>' . escape(g:NERDComLineSexyMap, '\') . ' <ESC>:call NERDComment(1,"sexy")<CR>'

    execute 'nmenu <silent> '. menuRoot .'.Yank\ line(s)\ then\ comment<TAB>' . escape(g:NERDComLineYankMap, '\') . ' "0Y' . g:NERDComLineMap
    execute 'vmenu <silent> '. menuRoot .'.Yank\ line(s)\ then\ comment<TAB>' . escape(g:NERDComLineYankMap, '\') . ' "0ygv' . g:NERDComLineMap

    execute 'nmenu <silent> '. menuRoot .'.Append\ Comment\ to\ Line<TAB>' . escape(g:NERDAppendComMap, '\') . ' :call NERDComment(0, "append")<cr>'
    execute 'nmenu <silent> '. menuRoot .'.Prepend\ Comment\ to\ Line<TAB>' . escape(g:NERDPrependComMap, '\') . ' :call NERDComment(0, "prepend")<cr>'

    execute 'menu <silent> '. menuRoot .'.-Sep-    :'

    execute 'nmenu <silent> '. menuRoot .'.Comment\ Align\ Left\ (nested)<TAB>' . escape(g:NERDComAlignLeftMap, '\') . ' :call NERDComment(0, "alignLeft")<CR>'
    execute 'vmenu <silent> '. menuRoot .'.Comment\ Align\ Left\ (nested)<TAB>' . escape(g:NERDComAlignLeftMap, '\') . ' <ESC>:call NERDComment(1, "alignLeft")<CR>'

    execute 'nmenu <silent> '. menuRoot .'.Comment\ Align\ Right\ (nested)<TAB>' . escape(g:NERDComAlignRightMap, '\') . ' :call NERDComment(0, "alignRight")<CR>'
    execute 'vmenu <silent> '. menuRoot .'.Comment\ Align\ Right\ (nested)<TAB>' . escape(g:NERDComAlignRightMap, '\') . ' <ESC>:call NERDComment(1, "alignRight")<CR>'

    execute 'nmenu <silent> '. menuRoot .'.Comment\ Align\ Both\ (nested)<TAB>' . escape(g:NERDComAlignBothMap, '\') . ' :call NERDComment(0, "alignBoth")<CR>'
    execute 'vmenu <silent> '. menuRoot .'.Comment\ Align\ Both\ (nested)<TAB>' . escape(g:NERDComAlignBothMap, '\') . ' <ESC>:call NERDComment(1, "alignBoth")<CR>'

    execute 'menu <silent> '. menuRoot .'.-Sep2-    :'

    execute 'menu <silent> '. menuRoot .'.Uncomment<TAB>' . escape(g:NERDUncomLineMap, '\') . ' :call NERDComment(0, "uncomment")<cr>'
    execute 'vmenu <silent>' . menuRoot.'.Uncomment<TAB>' . escape(g:NERDUncomLineMap, '\') . ' <esc>:call NERDComment(1, "uncomment")<cr>'

    execute 'menu <silent> '. menuRoot .'.-Sep3-    :'

    execute 'nmenu <silent> '. menuRoot .'.Use\ Alternative\ Delimiters<TAB>' . escape(g:NERDAltComMap, '\') . ' :call <SID>SwitchToAlternativeDelimiters(1)<CR>'


    execute 'imenu <silent> '. menuRoot .'.Insert\ Delims<TAB>' . escape(g:NERDComInInsertMap, '\') . ' <SPACE><BS><ESC>:call NERDComment(0, "insert")<CR>'

    execute 'menu '. menuRoot .'.-Sep4-    :'

    execute 'menu <silent>'. menuRoot .'.Help<TAB>:help\ NERDCommenterContents :help NERDCommenterContents<CR>'
endif
" vim: set foldmethod=marker :
