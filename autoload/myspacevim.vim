function! myspacevim#before() abort
    let g:neoformat_cpp_clangformat = { 'exe': "clang-format", 'args': ['--style=Google'] }
    let g:neoformat_enabled_cpp = ['clangformat']
    let g:spacevim_default_indent          = 4
    let g:spacevim_enable_cursorline       = 1

    " 重新映射 leader 键
    let g:mapleader = ','

    " vim-lsp-cxx-highlight 和这个选项存在冲突
    " let g:rainbow_active = 1
endfunction

function! myspacevim#after() abort
    let g:neomake_cpp_clang_maker = { 'exe': 'g++' }
    let g:neomake_cpp_enabled_makers = ["cpplint"]
    let g:neomake_cpp_cpplint_maker = { 'args': '' }
endfunction
