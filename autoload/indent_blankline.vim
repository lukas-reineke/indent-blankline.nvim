
function! indent_blankline#Init()

    try
        if len(nvim_list_uis()) ==# 0 || g:indent_blankline_enabled !=# v:true
            return
        endif

        let g:indent_blankline_nvim_instance = jobstart(
                    \ ['nvim', '--embed', '--headless', '-R', '--cmd', 'set sessionoptions='],
                    \ { 'rpc': v:true }
                    \ )

        call indent_blankline#Refresh()
    catch
        if g:indent_blankline_debug
            echohl Error
            echom 'indent-blankline encountered an error on init: ' . v:exception
            echohl None
        endif
    endtry

endfunction

function! indent_blankline#BufferEnabled()

    if exists('b:indent_blankline_enabled')
        if b:indent_blankline_enabled ==# v:true
            return v:true
        endif
        if b:indent_blankline_enabled ==# v:false
            return v:false
        endif
    endif

    if exists('b:indentLine_enabled')
        if b:indentLine_enabled ==# v:true
            return v:true
        endif
        if b:indentLine_enabled ==# v:false
            return v:false
        endif
    endif

    if index(g:indent_blankline_filetype_exclude, &filetype) != -1
        return v:false
    endif

    if index(g:indent_blankline_buftype_exclude, &buftype) != -1
        return v:false
    endif

    if len(g:indent_blankline_filetype) != 0 && index(g:indent_blankline_filetype, &filetype) == -1
        return v:false
    endif

    for name in g:indent_blankline_bufname_exclude
        if matchstr(bufname(''), name) == bufname('')
            return v:false
        endif
    endfor

    return v:true

endfunction

function! indent_blankline#Refresh()

    if g:indent_blankline_enabled !=# v:true || !indent_blankline#BufferEnabled()
        if get(b:, 'set_indent_blankline', v:false) && exists('g:indent_blankline_namespace')
            try
                call nvim_buf_clear_namespace(0, g:indent_blankline_namespace, 1, -1)
            catch
                if g:indent_blankline_debug
                    echohl Error
                    echom 'indent-blankline encountered an error while cleaning the namespace: ' . v:exception
                    echohl None
                endif
            endtry
        endif
        return
    endif

    if !exists('g:indent_blankline_nvim_instance')
        call indent_blankline#Init()
        return
    endif

    let l:shellslash = &shellslash
    set shellslash

    let l:file = expand('%:p')

    let &shellslash = l:shellslash

    if !filereadable(l:file)
        return
    endif

    try
        call rpcnotify(
                    \ g:indent_blankline_nvim_instance,
                    \ 'vim_command', 'call indent_blankline#embedded#FindMatches("' . l:file . '", ' . bufnr() . ')'
                    \ )
    catch /E475/
        call indent_blankline#Init()
        return
    catch
        if g:indent_blankline_debug
            echohl Error
            echom 'indent-blankline encountered an error on refresh: ' . v:exception
            echohl None
        endif
    endtry

    let b:set_indent_blankline = v:true

endfunction
