
let g:indent_blankline_namespace = nvim_create_namespace('indent_blankline')

function! indent_blankline#callback#ApplyMatches(result, bufnr)
    call nvim_buf_clear_namespace(a:bufnr, g:indent_blankline_namespace, 1, -1)

    let l:space = &l:shiftwidth == 0 ? &l:tabstop : &l:shiftwidth
    let l:n = len(g:indent_blankline_char_list)

    for l:match in a:result
        let l:v_text = []
        let l:level = 0

        for i in range(min([ l:match['indent'] / l:space, g:indent_blankline_indent_level ]))
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

endfunction

function! indent_blankline#callback#Error(exception)
    echom 'indent_blankline encountered an error: ' . a:exception
endfunction
