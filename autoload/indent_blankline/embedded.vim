
function! indent_blankline#embedded#FindMatches(file, bufnr)
    try
        keepjumps
        execute ':edit ' . a:file
        let l:view = winsaveview()
        call cursor(1, 1)

        let l:matches = []

        while 1
            let l:lnum = search('^$', 'W')

            if l:lnum ==# 0
                break
            endif

            let l:indent = 0

            if &indentexpr ==# 'lisp'
                let l:indent = lispindent(l:lnum)
            elseif &indentexpr !=# ''
                let l:current_view = winsaveview()
                let v:lnum = l:lnum
                execute('silent! let l:indent = '. &indentexpr)
                call winrestview(l:current_view)
            else
                let l:indent = cindent(l:lnum)
            endif

            if l:indent > 0
                call add(l:matches, { 'lnum': l:lnum, 'indent': l:indent })
            endif
        endwhile

        call rpcrequest(1, 'vim_eval', 'indent_blankline#callback#ApplyMatches([' . join(l:matches, ', ') . '], ' . a:bufnr . ')')
    catch
        call rpcrequest(1, 'vim_eval', 'indent_blankline#callback#Error("' . v:exception . '")')
    finally
        if exists('l:view')
            call winrestview(l:view)
            bdelete
        endif
    endtry
endfunction
