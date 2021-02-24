
if exists('g:loaded_indent_blankline') || !has('nvim-0.5.0')
    finish
endif
let g:loaded_indent_blankline = 1

let g:indent_blankline_char = get(g:, 'indent_blankline_char', get(g:, 'indentLine_char', '|'))
let g:indent_blankline_char_list = get(g:, 'indent_blankline_char_list', get(g:, 'indentLine_char_list', []))
let g:indent_blankline_char_highlight = get(g:, 'indent_blankline_char_highlight', 'Comment')
let g:indent_blankline_char_highlight_list = get(g:, 'indent_blankline_char_highlight_list', [])

let g:indent_blankline_space_char = get(g:, 'indent_blankline_space_char', indent_blankline#helper#GetListChar('space', ' '))
let g:indent_blankline_space_char_highlight = get(g:, 'indent_blankline_space_char_highlight', 'Whitespace')
let g:indent_blankline_space_char_highlight_list = get(g:, 'indent_blankline_space_char_highlight_list', [])

let g:indent_blankline_space_char_blankline = get(g:, 'indent_blankline_space_char_blankline', g:indent_blankline_space_char)
let g:indent_blankline_space_char_blankline_highlight = get(g:, 'indent_blankline_space_char_blankline_highlight', g:indent_blankline_space_char_highlight)
let g:indent_blankline_space_char_blankline_highlight_list = get(g:, 'indent_blankline_space_char_blankline_highlight_list', g:indent_blankline_space_char_highlight_list)

let g:indent_blankline_indent_level = get(g:, 'indent_blankline_indent_level', get(g:, 'indentLine_indentLevel', 20))
let g:indent_blankline_enabled = get(g:, 'indent_blankline_enabled', get(g:, 'indentLine_enabled', v:true))
let g:indent_blankline_filetype = get(g:, 'indent_blankline_filetype', get(g:, 'indentLine_fileType', []))
let g:indent_blankline_filetype_exclude = get(g:, 'indent_blankline_filetype_exclude', get(g:, 'indentLine_fileTypeExclude', []))
let g:indent_blankline_bufname_exclude = get(g:, 'indent_blankline_bufname_exclude', get(g:, 'indentLine_bufNameExclude', []))
let g:indent_blankline_buftype_exclude = get(g:, 'indent_blankline_buftype_exclude', get(g:, 'indentLine_bufTypeExclude', []))
let g:indent_blankline_extra_indent_level = get(g:, 'indent_blankline_extra_indent_level', 0)
let g:indent_blankline_viewport_buffer = get(g:, 'indent_blankline_viewport_buffer', 10)
let g:indent_blankline_use_treesitter = get(g:, 'indent_blankline_use_treesitter', v:false)
let g:indent_blankline_debug = get(g:, 'indent_blankline_debug', v:false)
let g:indent_blankline_disable_warning_message = get(g:, 'indent_blankline_disable_warning_message', v:false)
let g:indent_blankline_show_first_indent_level = get(g:, 'indent_blankline_show_first_indent_level', v:true)
let g:indent_blankline_show_trailing_blankline_indent = get(g:, 'indent_blankline_show_trailing_blankline_indent', v:true)
let g:indent_blankline_strict_tabs = get(g:, 'indent_blankline_strict_tabs', v:false)

lua require("indent_blankline").setup()

command! IndentBlanklineRefresh call indent_blankline#Refresh()

command! IndentBlanklineEnable call indent_blankline#commands#Enable()
command! IndentBlanklineDisable call indent_blankline#commands#Disable()
command! IndentBlanklineToggle call indent_blankline#commands#Toggle()

command! IndentBlanklineEnableAll call indent_blankline#commands#EnableAll()
command! IndentBlanklineDisableAll call indent_blankline#commands#DisableAll()
command! IndentBlanklineToggleAll call indent_blankline#commands#ToggleAll()

function s:IndentBlanklineInit()
    if exists(':IndentLinesEnable') && !g:indent_blankline_disable_warning_message
        echohl Error
        echom 'indent-blankline does not require IndentLine anymore, please remove it.'
        echohl None
    endif
    let l:win_id = win_getid()
    windo IndentBlanklineRefresh
    call win_gotoid(l:win_id)
endfunction

augroup IndentBlanklineAutogroup
    autocmd!
    autocmd OptionSet shiftwidth,tabstop IndentBlanklineRefresh
    autocmd FileChangedShellPost,Syntax,TextChanged,TextChangedI,WinScrolled * IndentBlanklineRefresh
    autocmd VimEnter * call s:IndentBlanklineInit()
augroup END

