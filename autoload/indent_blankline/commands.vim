
function! indent_blankline#commands#Enable()
    let b:indent_blankline_enabled = v:true
    call indent_blankline#Refresh()
endfunction

function! indent_blankline#commands#Disable()
    let b:indent_blankline_enabled = v:false
    let b:set_indent_blankline = v:false
    if exists('g:indent_blankline_namespace')
        call nvim_buf_clear_namespace(0, g:indent_blankline_namespace, 1, -1)
    endif
endfunction

function! indent_blankline#commands#Toggle()
    if get(b:, 'set_indent_blankline', v:false)
        call indent_blankline#commands#Disable()
    else
        call indent_blankline#commands#Enable()
    endif
endfunction

function! indent_blankline#commands#EnableAll()
    call indent_blankline#commands#Enable()
    if exists(':IndentLinesEnable')
        IndentLinesEnable
    endif
endfunction

function! indent_blankline#commands#DisableAll()
    call indent_blankline#commands#Disable()
    if exists(':IndentLinesDisable')
        IndentLinesDisable
    endif
endfunction

function! indent_blankline#commands#ToggleAll()
    call indent_blankline#commands#Toggle()
    if exists(':IndentLinesToggle')
        IndentLinesToggle
    endif
endfunction
