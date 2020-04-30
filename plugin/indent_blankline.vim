
if exists('g:loaded_indent_blankline') || !has('nvim-0.4.0')
    finish
endif
let g:loaded_indent_blankline = 1

let g:indent_blankline_char = get(g:, 'indent_blankline_char', get(g:, 'indentLine_char', '|'))
let g:indent_blankline_space_char = get(g:, 'indent_blankline_space_char', indent_blankline#helper#GetListChar('space', ' '))
let g:indent_blankline_char_list = get(g:, 'indent_blankline_char_list', get(g:, 'indentLine_char_list', []))
let g:indent_blankline_indent_level = get(g:, 'indent_blankline_indent_level', get(g:, 'indentLine_indentLevel', 20))
let g:indent_blankline_enabled = get(g:, 'indent_blankline_enabled', get(g:, 'indentLine_enabled', v:true))
let g:indent_blankline_filetype = get(g:, 'indent_blankline_filetype', get(g:, 'indentLine_fileType', []))
let g:indent_blankline_filetype_exclude = get(g:, 'indent_blankline_filetype_exclude', get(g:, 'indentLine_fileTypeExclude', []))
let g:indent_blankline_bufname_exclude = get(g:, 'indent_blankline_bufname_exclude', get(g:, 'indentLine_bufNameExclude', []))
let g:indent_blankline_buftype_exclude = get(g:, 'indent_blankline_buftype_exclude', get(g:, 'indentLine_bufTypeExclude', []))
let g:indent_blankline_extra_indent_level = get(g:, 'indent_blankline_extra_indent_level', 0)
let g:indent_blankline_debug = get(g:, 'indent_blankline_debug', v:false)


command! IndentBlanklineRefresh call indent_blankline#Refresh()

command! IndentBlanklineEnable call indent_blankline#commands#Enable()
command! IndentBlanklineDisable call indent_blankline#commands#Disable()
command! IndentBlanklineToggle call indent_blankline#commands#Toggle()

command! IndentBlanklineEnableAll call indent_blankline#commands#EnableAll()
command! IndentBlanklineDisableAll call indent_blankline#commands#DisableAll()
command! IndentBlanklineToggleAll call indent_blankline#commands#ToggleAll()

augroup IndentBlanklineAutogroup
    autocmd!
    autocmd Syntax * IndentBlanklineRefresh
    autocmd BufWritePost * IndentBlanklineRefresh
    autocmd FileChangedShellPost * IndentBlanklineRefresh
    autocmd OptionSet shiftwidth,tabstop IndentBlanklineRefresh
augroup END
