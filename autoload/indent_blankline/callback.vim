
let g:indent_blankline_namespace = nvim_create_namespace('indent_blankline')

function! indent_blankline#callback#ApplyMatches(result, bufnr)
    try
        call nvim_buf_clear_namespace(a:bufnr, g:indent_blankline_namespace, 1, -1)
    catch
        if g:indent_blankline_debug
            echohl Error
            echom 'indent-blankline encountered an error while cleaning the namespace: ' . v:exception
            echohl None
        endif
        return
    endtry

    try
        let l:space = &l:shiftwidth == 0 ? &l:tabstop : &l:shiftwidth
        let l:n = len(g:indent_blankline_char_list)

        for l:match in a:result
            let l:v_text = []
            let l:level = 0
            let l:indent_level = l:match['indent'] / l:space

            if g:indent_blankline_extra_indent_level
                let l:indent_level = l:indent_level + g:indent_blankline_extra_indent_level
            endif

            for i in range(min([max([l:indent_level, 0]), g:indent_blankline_indent_level]))
                if n > 0
                    let l:char = g:indent_blankline_char_list[level % n]
                    let l:level += 1
                else
                    let l:char = g:indent_blankline_char
                endif

                call add(l:v_text, [repeat(g:indent_blankline_space_char, l:space - 1), 'Whitespace'])
                call add(l:v_text, [l:char, 'Conceal'])
            endfor

            call nvim_buf_set_virtual_text(a:bufnr, g:indent_blankline_namespace, l:match['lnum'] - 1, l:v_text, {})
        endfor
    catch
        if g:indent_blankline_debug
            echohl Error
            echom 'indent-blankline encountered an error while applying matches: ' . v:exception
            echohl None
        endif
    endtry

endfunction

function! indent_blankline#callback#Error(exception)
    if g:indent_blankline_debug
        echohl Error
        echom 'indent-blankline encountered an error while finding matches: ' . a:exception
        echohl None
    endif
endfunction
