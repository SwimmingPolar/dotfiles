function! Findkey(key)
  " Get the mapping details
  let l:mapping = execute('verbose map ' . a:key)
  
  " Find the file and line number from the output
  if match(l:mapping, 'Last set from') != -1
    let l:line = matchstr(l:mapping, 'line \zs\d\+')
    let l:file = matchstr(l:mapping, 'Last set from \zs.*\.vim')
    
    " Open the file at the specific line in a vertical split
    execute 'vsplit +' . l:line . ' ' . l:file
  else
    echo "No mapping found for " . a:key
  endif
endfunction

:command! -nargs=1 Findkey call Findkey(<f-args>)
