function IsDirty() 
    return getbufinfo(bufnr(@%))[0].changed
endfunction

function! SaveIfDirty()
    if (IsDirty())
        silent execute "w"
    endif
endfunction

function GetBaseName(filename)
    return fnamemodify(a:filename, ":t:r")
endfunction

function CompareLastUsed(v1, v2)
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
function NextMatching(expr, n)
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


" Get the next matching buffer with the same base name
function GetMatching()
    let thisName = expand('%:t:r')
    let expr = "fnamemodify(v:val.name, ':t:r') == '" . thisName . "'"

    return NextMatching(expr, 1)
endfunction

function! GetSourceFiles(ext)
    let sources = system('find . -name "*.' . a:ext . '" -o -path ./coolgen -prune -false')
    let charArr = str2list(sources)

    let idx = 0
    let lst = []
    let cur = ""

    for char in charArr
        if char == 10
            let lst += [cur]
            let cur = ""
        else
            let cur = cur . nr2char(char)
        endif
    endfor
    return lst
endfunction

function! GetHeaderOrSource () 
    call SaveIfDirty()
    let matching = GetMatching()
    if (matching >= 0)
        execute "buffer " . matching
        return
    endif

    let ext=expand('%:e')
    let filenameNoExt=expand('%:t:r')
    let base="./src/"

    if (ext!='c' && ext!='h')
        echom "Current file is not a .c or .h file."
        return
    endif

    if (ext=='c')
        let file = "./include/" . filenameNoExt . '.h'
    else
        let file = "./src/" . filenameNoExt . '.c'
    endif

    execute "edit " . file

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
