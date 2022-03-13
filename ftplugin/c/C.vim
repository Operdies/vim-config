if (!exists('g:CVimFunctionsLoaded'))
    let g:CVimFunctionsLoaded=1

    function! IsDirty() 
        return getbufinfo(bufnr(@%))[0].changed
    endfunction

    function! SaveIfDirty()
        if (IsDirty())
            silent execute "w"
        endif
    endfunction

    function! GetBaseName(filename)
        return fnamemodify(a:filename, ":t:r")
    endfunction

    function! CompareLastUsed(v1, v2)
        return a:v1.lastused - a:v2.lastused
    endfunction

    let g:CompileBufNo = 0
    function! CreateCompileBuffer()
        enew
        set buftype=nofile
        execute "silent file CompileOutputBuffer" . g:CompileBufNo
        resize 16
        let g:CompileBufNo = g:CompileBufNo + 1
    endfunction

    function! TriggerVisualBell()
        execute "normal! \<C-\>\<C-n>\<Esc>"
    endfunction

    "Switch n buffers forward if that buffer matches the given expression
    function! NextMatching(expr, n)
        if (IsDirty())
            execute "w"
        endif

        let cur = getbufinfo('')[0]

        let buffers = getbufinfo()
        let buffers = filter(buffers, a:expr)

        let idx = index(buffers, cur)
        let target = idx + a:n

        if target >= len(buffers)
            let target = target % len(buffers)
        endif

        let res = buffers[target]
        return res.bufnr
    endfunction

    " Selects the next buffer of same extension as current buffer
    function! NextOfKind(mod)
        " get buffers with the same extension
        let ext=expand('%:e')
        let expr = "fnamemodify(v:val.name, ':e') == '" . ext . "'"
        let cnt = (v:count == 0 ? 1 : v:count) * a:mod
        let bufnr = NextMatching(expr, cnt)
        execute "buffer " . bufnr
    endfunction

    function! GetHeaderOrSource() 
        call SaveIfDirty()

        let ext=expand('%:e')

        if (ext != 'h' && ext != 'c')
            echo "Not a C file."
            return
        endif
        let filenameNoExt=expand('%:t:r')

        let tagged = taglist(filenameNoExt)
        for fn in tagged
            let fnExt = fnamemodify(fn.name, ':e')
            if (fnExt == ext)
                continue
            endif
            execute "edit " . fn.filename
            return
        endfor
        echo "No file in tag list matching " . fileNameNoExt "." . ext
    endfunction

    " Return true if this split has no adjacent splits (left / right)
    function! SoloRow()
        let curNr = winnr()

        wincmd h
        " There is another split to the right of this one
        if winnr() != curNr
            wincmd p
            return 0
        endif

        wincmd l
        " There is another split to the left of this one
        if winnr() != curNr
            wincmd p
            return 0
        endif

        return 1
    endfunction

    function! DoCompile(CompileCommand)
        call SaveIfDirty() 
        " stdbuf --output=L forces line buffering for stdout
        execute "AsyncRun stdbuf --output=L " . a:CompileCommand 
    endfunction

    function! DoCommand(Command)
        call SaveIfDirty()

        execute a:Command
        call TriggerVisualBell()
    endfunction

    function! TryRun()
        let ext=expand('%:e')

        if (ext=="c" || ext=="h")
            call DoCompile("make run")
        elseif (ext=="sh")
            call DoCompile("bash " . @%)
        else
            echom "No commands registered to execute ." . ext " files."
        endif
    endfunction
endif

nmap <buffer><LEADER><tab> :call GetHeaderOrSource()<CR>
nmap <buffer><F1> :<c-u> call NextOfKind(1)<CR>
nmap <buffer><F2> :<c-u> call NextOfKind(-1)<CR>
nmap <buffer><LEADER>r :call TryRun()<CR>
nmap <buffer><LEADER>c :call SaveIfDirty()<CR>:AsyncRun make<CR>
nmap <buffer><LEADER>s :AsyncStop<CR>
nmap <buffer><LEADER>t :tag 

" Clang format
let g:clang_format#style_options = {
            \ "AccessModifierOffset" : -4,
            \ "AllowShortIfStatementsOnASingleLine" : "true",
            \ "AlwaysBreakTemplateDeclarations" : "true",
            \ "Standard" : "C++11"}

" map to <Leader>cf in C++ code
nnoremap <buffer><Leader>gf :<C-u>ClangFormat<CR>
vnoremap <buffer><Leader>gf :ClangFormat<CR>

setlocal foldmethod=syntax
setlocal foldlevel=99
