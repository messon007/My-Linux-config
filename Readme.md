# neovim的C/C++配置


<details open="">
  <summary>目录</summary>
<!-- vim-markdown-toc GitLab -->

- [前言](#前言)
- [关于 lsp 和 async ](#关于-language-server-protocal-和-async-)
- [install](#安装)
- [Work with Linux Kernel](#查看Linux内核)
- [基本操作](#基本操作)
    - [search](#search)
    - [file tree](#file-tree)
    - [window](#window)
    - [buffer](#buffer)
    - [navigate](#navigate)
    - [define reference](#define-reference)
    - [comment](#comment)
    - [documentation](#documentation)
    - [snippet](#snippet)
    - [git](#git)
    - [format](#format)
    - [rename](#rename)
    - [debug](#debug)
    - [terminal](#terminal)
- [扩展](#扩展)
    - [基于SpaceVim的扩展 以Latex为例子](#基于spacevim的扩展-以latex为例子)
    - [基于coc.nvim的扩展 以Python为例](#基于cocnvim的扩展-以python为例)
- [本配置源代码解释](#本配置源代码解释)
- [其他的一些资源](#其他的一些资源)


<!-- vim-markdown-toc -->
</details>

## 前言

**至少在我放弃使用tagbar，ctags，nerdtree，YouCompleteMe的时候**，这些工具各有各的或大或小的问题，这些问题集中体现在性能和精度，而这两个问题被 async 和 lsp 完美的解决了。

我平时主要C/C++，处理的工程小的有 : 刷Leetcode(几十行)，中型的有 : ucore 试验(上万行)，linux kernel(千万行)，用目前的配置都是丝般顺滑。当然，得益于coc.nvim的强大，本配置也可以较好的处理Python，Java，Rust等语言。

本文使用neovim + [SpaceVim](http://spacevim.org/) + [coc.nim](https://github.com/neoclide/coc.nvim)来搭建c/c++开发环境。SpaceVim的默认提供各种基础设施的解决方案，比如status line，搜索，markdown预览高亮，其也虽然提供了 [C/C++ 的配置](https://spacevim.org/layers/lang/c/)，但是我个人觉得并不好用，而coc.nvim吸收了VSCode的优点(允许安装VSCode插件的coc插件版本)。

## 关于 [Language Server Protocol](https://microsoft.github.io/language-server-protocol/) 和 async 
### lsp是什么
lsp 定义了一套标准编辑器和 language server 之间的规范。不同的语言需要不同的Language Server，比如C/C++ 需要 [ccls](https://github.com/MaskRay/ccls), Rust语言采用[rls](https://github.com/rust-lang/rls)，Language server 的清单在[这里](https://microsoft.github.io/language-server-protocol/implementors/servers/)。在lsp的另一端，也就是编辑器这一端，也需要对应的实现，其列表在[这里](https://microsoft.github.io/language-server-protocol/implementors/tools/)。也就是说，由于lsp的存在，一门语言的language server可以用于所有的支持lsp的编辑器上，大大的减少了重复开发。其架构图大概如下，另外 neovim 逐步会将lsp内置到编辑器中间，所以 Editor Plugin 层将来就不需要了。
```
 +------------------------+    +---------------------------+    +-----------------------+
 |                        |    |                           |    |                       |
 |     Atom               |    |   coc.nvim                |    |                       |
 |     Emacs              +--> |   LanguageClient-neovim   +--> |   clangd/ccls/cquery  |
 |     Vim/Neovim         |    |   vim-lsp                 |    |                       |
 |     Visual Studio Code |    |                           |    |                       |
 |     Monaco Editor      |    |                           |    |                       |
 +------------------------+    +---------------------------+    +-----------------------+
 |                        |    |                           |    |                       |
 |      Editor            | <--+  Editor Plugin            | <--+   Language Server     |
 |                        |    |                           |    |                       |
 |                        |    |                           |    |                       |
 +------------------------+    +---------------------------+    +-----------------------+
```
### lsp的作用：
* 让静态检查变得异常简单，当不小心删除掉一个`put_swap_page`这个函数字符之后，立刻得到提示。

* 基于lsp的高亮，函数，变量，宏，关键字都是有自己的颜色，但是基本的高亮就只有关键字进行了高亮。lsp是基于语义的高亮，类型 `swp_entry_t`, 宏 `xa_lock_irq`, 成员 `i_pages` 等都是使用特定的颜色，而基本高亮只有 `void` `struct` 显示了高亮。

* 自动完成，这是其最重要的功能。

当使用上了lsp之后，之前写C/C++P必备的[YCM](https://github.com/ycm-core/YouCompleteMe)(用于自动补全，静态检查等)和[ctags](https://github.com/universal-ctags/ctags)就不需要了。YCM对于大型项目显得笨拙，ctags 不是基于语义的索引，而是基于字符串匹配实现，所以会出现误判，比如两个文件中间都定义了 static 的同名函数，ctags 往往会将两者都找出来。gtags 解决了 ctags 查找引用的问题，其同样支持大量的语言，但是跳转精度，索引自动生成等根本问题没有被解决。

利用 coc.nvim 可以获取极佳的 lsp 体验 ，因为 lsp 是微软开发 vscode 提出的，coc.nvim 的宗旨就是*full language server protocol support as VSCode*。

### async
另一个新特性是 **async** (异步机制)。async 的特点就是快，当一个插件存在其async的版本，那么毫无疑问，使用async版本。[nerdtree](https://github.com/preservim/nerdtree) 使用vim的人应该是无人不知，我之前一直都是使用这一个插件的，直到有一天我用vim打开linux kernel，并且打开nerdtree之后，光标移动都非常的困难，我开始以为是终端的性能问题，后来以为是lsp的问题，直到将nerdtree替换为[大神shougou的defx](https://github.com/Shougo/defx.nvim)。我想，如果没有 SpaceVim，我永远都不要找到 defx 这一个插件。

### 支持lsp的开源项目
在2019.7.24，linux 内核的.gitignore增加了对于lsp的支持。
![内核的gitignore](https://upload-images.jianshu.io/upload_images/9176874-8d57913135875846.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 关于Neovim
Neovim is a Vim-based text editor engineered for extensibility and usability. 
Neovim is a refactor, and sometimes redactor, in the tradition of Vim (which itself derives from Stevie). It is not a rewrite but a continuation and extension of Vim. Many clones and derivatives exist, some very clever—but none are Vim. Neovim is built for users who want the good parts of Vim, and more.
其配置文件为.config/nvim

## 关于SpaceVim
SpaceVim 是一个社区驱动的模块化的 Vim IDE，以模块的方式组织管理插件以及相关配置， 为不同的语言开发量身定制了相关的开发模块，该模块提供代码自动补全， 语法检查、格式化、调试、REPL 等特性。用户仅需载入相关语言的模块即可得到一个开箱即用的 Vim IDE。SpaceVim 挑选了优质插件，基本可以实现开箱即用。另外vimawesome也是一个vim插件市场, 可能不如SpaceVim好用。

## install
安装说明：
1. 代理: 尽管 python, pacman/apt-get/yum，npm, docker 都是可以使用国内镜像，但是部分还是需要国外的，比如 Microsoft Python Language Server. 实现代理的方法在 github 上有很多教程，也可以参考[我的 blog](https://martins3.github.io/gfw.html)
2. 本配置的架构如下图所示。
```
+-----------------+
|                 |
|     my config   | 定制Neovim, SpaceVim和coc.nvim的配置，添加coc.nvim的插件; init.toml, plugin/coc.vim, plugin/defx.vim和autoload/myspacevim.vim
|                 |
+-----------------+
|                 |
|     Coc.nvim    | 作为SpaceVim的插件，在SpaceVim的autocomplet_method为coc时会要求启用lsp层，此时coc作为language-server的前端。
|                 | coc.nvim同样可以添加插件，比如 coc-clang。其插件等会被自动安装在.config/coc/extensions
+-----------------+
|                 | 基于neovim的vim ide, 支持模块化(每个模块包装了多个vim插件)的插件管理方法, 以layer层级来管理模块。也支持客户定制的插件。
|     SpaceVim    | 其配置文件为: .SpaceVim (将~/.config/nvim软链接到~/.SpaceVim) 
|                 | 其允许再次定制，目录为.SpaceVim.d/; 包含init.toml, plugin/coc.vim, plugin/defx.vim和autoload/myspacevim.vim
+-----------------+ 
|                 |
|     Neovim      | 编辑器而已. 其配置文件为: ~/.config/nvim/init.vim; windows下为~/AppData/Local/nvim/init.vim
|                 | 安装后在目录/usr/share/nvim/runtime/能查到其内置的插件.
+-----------------+
```
整个环境的安装主要是 neovim SpaceVim coc.nvim ccls，下面说明一下安装主要步骤以及其需要注意的一些问题。

1. 推荐使用 [neovim](https://github.com/neovim/neovim/wiki/Installing-Neovim)，由于neovim的更新速度更快，新特性支持更好。安装完成之后检查版本，最好大于v0.4.0.
```
➜  Vn git:(master) ✗ sudo apt install neovim
➜  Vn git:(master) ✗ nvim --version
NVIM v0.4.3
Build type: Release
LuaJIT 2.0.5
Compilation: /usr/bin/cc -march=x86-64 -mtune=generic -O2 -pipe -fno-plt -O2 -DNDEBUG -DMIN_LOG_LEVEL=3 -Wall -Wextra -pedantic -Wno-unused-parameter -Wstrict-prototypes -std=gnu99 -Wshadow -Wconversion -Wmissing-prototypes -Wimplicit-fallthrough -Wvla -fstack-protector-strong -fdiagnostics-color=always -DINCLUDE_GENERATED_DECLARATIONS -D_GNU_SOURCE -DNVIM_MSGPACK_HAS_FLOAT32 -DNVIM_UNIBI_HAS_VAR_FROM -I/build/neovim/src/build/config -I/build/neovim/src/neovim-0.4.3/src -I/usr/include -I/build/neovim/src/build/src/nvim/auto -I/build/neovim/src/build/include
Compiled by builduser

Features: +acl +iconv +tui
See ":help feature-compile"

   system vimrc file: "$VIM/sysinit.vim"
  fall-back for $VIM: "/usr/share/nvim"

Run :checkhealth for more info
```

2. 按照Spacevim 安装的[官方文档](https://spacevim.org/cn/quick-start-guide/)安装SpaceVim。只为neovim安装Spacevim用:
```
curl -sLf https://spacevim.org/cn/install.sh | bash -s -- --install neovim
```

3. 安装npm和yarn, **保证yarn/npm使用国内镜像, 部分插件需要使用yarn/npm安装, 如果不切换为国内镜像, ***很容易***出现安装失败.**，切换方法参考[这里](https://zhuanlan.zhihu.com/p/35856841). 安装完成之后检查:
```
➜  Vn git:(master) ✗ yarn config get registry && npm config get registry
https://registry.npm.taobao.org
https://registry.npm.taobao.org/
```
4. 安装ccls。也可以参考其[官方文档](https://github.com/MaskRay/ccls/wiki/Build)手动编译获取最新版。
```
➜  Vn git:(master) ✗ sudo apt install ccls
➜  Vn git:(master) ✗ ccls -version
ccls version 0.20190823.6-1~ubuntu1.20.04.1
clang version 10.0.0-4ubuntu1
```
5. 下载本配置(目录.SpaceVim.d), 在此基础上定制自己的配置。会使能coc和lsp.
```sh
cd ~ # 保证在根目录
rm -r .SpaceVim.d # 将原来的配置删除
git clone https://github.com/martins3/My-Linux-config .SpaceVim.d 
nvim # 打开vim 将会自动安装所有的插件
```
init.toml
```
# All SpaceVim option below [option] section
[options]
    # set spacevim theme. by default colorscheme layer is not loaded,
    # if you want to use more colorscheme, please load the colorscheme
    # layer
    colorscheme = "gruvbox"
    colorscheme_bg = "dark"
    # Disable guicolors in basic mode, many terminal do not support 24bit
    # true colors
    enable_guicolors = false
    # Disable statusline separator, if you want to use other value, please
    # install nerd fonts
    statusline_separator = "nil"
    statusline_iseparator = "nil"
    buffer_index_type = 4
    windows_index_type = 3

    enable_tabline_filetype_icon = false
    enable_statusline_mode = false
    statusline_unicode_symbols = false
    # left sections of statusline
    statusline_left_sections = [
        'winnr',
	    ]
    # right sections of statusline
    statusline_right_sections = [
       'percentage'
    ]

    # Enable vim compatible mode, avoid changing origin vim key bindings
    vimcompatible = true
    default_indent = 4
    enable_cursorline = 0

    # customize option
    snippet_engine = "ultisnips"
    filemanager = "defx"
    # filemanager = "nerdtree"
    # autocomplete module
    autocomplete_method = "coc" # require enable lsp module
    bootstrap_before = "myspacevim#before"
    bootstrap_after = "myspacevim#after"
    enable_neomake = false
    
    # disable built-in plugin
    # disabled_plugins = ["neomake.vim"]

# Enable autocomplete layer
[[layers]]
    name = 'autocomplete'
    auto_completion_return_key_behavior = "complete"
    auto_completion_tab_key_behavior = "cycle"
    auto_completion_enable_snippets_in_popup = false
    autocomplete_parens = true

[[layers]]
    name = "VersionControl"
    enable = false

[[layers]]
    name = "checkers"
    enable = false

[[layers]]
    name = "core#statusline"

[[layers]]
    name = "core#banner"
    enable = false
   
[[layers]]
    name = "core#tabline"

[[layers]]
    name = 'core'
    filetree_show_hidden = true

[[layers]]
    name = 'shell'
    default_position = 'top'
    default_height = 30

[[layers]]
    name = "lang#c"
    clang_executable = "g++"
    clang_flag = ['-I/user/include']
    enable_clang_syntax_highlight = false

    [layer.clang_std]
        c = "c11"
        cpp = "c++1z"

[[layers]]
  name = 'lsp'
  filetypes = [
    'c',
    'cpp'
  ]
  [layers.override_cmd]
      c = ['ccls', '--log-file=/tmp/ccls.log']
      cpp = ['ccls', '--log-file=/tmp/ccls.log']

[[layers]]
    name = "format"

# fuzzy search
[[layers]]
  name = "fzf"

[[layers]]
    name = "cscope"
    enable = false

[[layers]]
    name = "gtags"
    gtagslabel = "pygments"
    enable = false

# 基于lsp的高亮插件
[[custom_plugins]]
    name = 'jackguo380/vim-lsp-cxx-highlight'


# 主要用于快速搜索 文件, buffer 和 函数
[[custom_plugins]]
    name = "Yggdroot/LeaderF"
    build = "./install.sh"
```
Here is my configuration in SpaceVim.d/autoload/myspacevim.vim
```
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
```

Here is my configuration in SpaceVim.d/plugin/coc.vim

```
" coc.nvim 的配置, 来自于 https://github.com/neoclide/coc.nvim

" Use <c-space> for trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

set hidden

" Some servers have issues with backup files, see #649
set nobackup
set nowritebackup

" 使用 Microsoft Python Language Server 不然 coc.nvim 会警告
call coc#config("python.jediEnabled", v:false)

call coc#config("smartf.wordJump", v:false)
call coc#config("smartf.jumpOnTrigger", v:false)

call coc#config('coc.preferences', {
                        \ "autoTrigger": "always",
                        \ "maxCompleteItemCount": 10,
                        \ "codeLens.enable": 1,
                        \ "diagnostic.virtualText": 1,
                        \})

" c/c++ golang 和 bash 的 language server 设置
call coc#config("languageserver", {
      \"ccls": {
      \  "command": "ccls",
      \  "filetypes": ["c", "cpp"],
      \  "rootPatterns": ["compile_commands.json", ".svn/", ".git/"],
      \  "index": {
      \     "threads": 8
      \  },
      \  "initializationOptions": {
      \     "cache": {
      \       "directory": ".ccls-cache"
      \     },
      \     "highlight": { "lsRanges" : v:true }
      \   },
      \  "client": {
      \    "snippetSupport": v:false
      \   }
      \},
      \"bash": {
      \  "command": "bash-language-server",
      \  "args": ["start"],
      \  "filetypes": ["sh"],
      \  "ignoredRootPaths": ["~"]
      \},
      \})

call coc#config("git.addGBlameToVirtualText", v:true)
call coc#config("git.virtualTextPrefix", "👋 ")

" coc.nvim 插件，用于支持 python 等语言
let s:coc_extensions = [
      \ 'coc-python',
      \ 'coc-dictionary',
      \ 'coc-tag',
      \ 'coc-json',
      \ 'coc-yaml',
      \ 'coc-cmake',
      \ 'coc-lists',
                        \]
for extension in s:coc_extensions
        call coc#add_extension(extension)
endfor

" Use <cr> for confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references-used)

" Use K for show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if &filetype == 'vim'
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Remap for rename current word and it doesn't work
" nmap <leader>rn <Plug>(coc-rename)

" 注释掉，一般使用 `Space` `r` `f` 直接格式化整个文件
" Remap for format selected region
" vmap <leader>f  <Plug>(coc-format-selected)
" nmap <leader>f  <Plug>(coc-format-selected)

" Use `:Format` for format current buffer
command! -nargs=0 Format :call CocAction('format')

" Use `:Fold` for fold current buffer
command! -nargs=? Fold :call     CocAction('fold', <f-args>)
```

6. 启动nvim, 其会自动安装所需的插件。然后在nvim中执行 `checkhealth` 命令，其会提醒需要安装的各种依赖。
安装的插件目录应该在.cache/vimfiles/repos/github.com/底下. 

7. 安装[bear](https://github.com/rizsotto/Bear)。ccls 需要通过 bear 生成的 compile_commands.json 来构建索引数据。
```
sudo apt install bear
```

注：使用 bear 生成 compile_commands.json 是一种通用的方法，但是不同的 build 工具和项目还存在一些捷径可走:
1. linux 内核使用自带的脚本 `scripts/clang-tools/gen_compile_commands.py`，具体可以参考[这里](https://patchwork.kernel.org/patch/10717125/)，这样的话就不用更改一次 .config 就重新编译整个内核。
2. cmake [生成 compile_commands.json 的方法](https://stackoverflow.com/questions/23960835/cmake-not-generating-compile-commands-json)
3. [ninja](https://ninja-build.org/manual.html)
```
ninja -t compdb > compile_commands.json
```
4. [ccls documentation for more](https://github.com/MaskRay/ccls/wiki/Project-Setup)

## Work with Linux Kernel
```
git clone https://mirrors.tuna.tsinghua.edu.cn/git/linux.git
cd linux
# 使用标准配置，参考 :  https://www.linuxtopia.org/online_books/linux_kernel/kernel_configuration/ch11s03.html
make defconfig
# 编译内核
make -j8
# 在 xxx 之后的内核中间, 利用生成 compile_commands.json
scripts/clang-tools/gen_compile_commands.py
# 第一次打开的时候，ccls 会生成索引文件，此时风扇飞转属于正常现象，之后不会出现这种问题
nvim 
```
一个工程只要生成 compile_commands.json，那么一切就大功告成了。

## 基本操作
默认为vim兼容模式，详细的操作请移步到SpaceVim, coc.nvim, ccls 以及特定插件的文档。

注意: vim 默认的 leader 键，加上前面提到的两个特殊功能leader, 一共存在三个 leader 键，其功能总结如下:
| `,`                         | `c`      | `Space`  |
|-----------------------------|----------|----------|
| 通用leader 键，包含各种作用 | 窗口操作 | SpaceVim使用|
这三个键位都是可以重新映射的。

#### search
[vim-searchindex](https://github.com/google/vim-searchindex) 可以显示当前是第几个文本项.

spacevim 配置提供了强大的[异步搜索功能](https://spacevim.org/grep-on-the-fly-in-spacevim/), 比较常用的是:

| key binding     | function                                  |
|-----------------|-------------------------------------------|
| `Space` `s` `/` | 实时动态搜索(grep on the fly)             |
| `Space` `s` `p` | 搜索整个工程                              |
| `Space` `s` `b` | 搜索所有打开的 buffer                     |
| `Space` `s` `P` | **对于光标所在字符**搜索整个工程          |
| `Space` `s` `b` | **对于光标所在字符**搜索所有打开的 buffer |

#### file tree
参考SpaceVim的[文档](https://spacevim.org/documentation/#file-tree)，我这里总结几个我常用的:
| key binding     | function                                          |
|-----------------|---------------------------------------------------|
| `Space` `f` `o` | 将当前的文件显示在filetree中间              |
| `r`             | 相当于shell中间的mv命令，实现文件的重命名或者移动 |
| `d`             | 删除                                              |
| `j`             | 向下移动                                          |
| `k`             | 向上移动                                          |

更多配置可直接阅读SpaceVim里defx插件的源码, 位置在 : `~/.SpaceVim/config/plugins/defx.vim`

#### window
1. `<Tab>` : 进入下一个窗口
2. `c` `g` : 水平拆分窗口。因为 window leader 键位被我重新映射为 `c`，如果是被映射其他键位，比如 `x`, 那么水平拆分为 `x` `g`
```vim
    " 重新映射 window leader 键位
    let g:spacevim_windows_leader = 'c'
```
3. `q` : 关闭窗口
4. `<Space>` `w` `m` 当前窗口最大化
5. 利用 [vim-smoothie](https://github.com/psliwka/vim-smoothie) 的 `Ctrl` `e` 和 `Ctrl` `y` 可以更加丝滑的翻页  

#### buffer
1. `,` `b` : 搜索 buffer，前面提到过的，这个主要用于打开的 buffer 的数量非常多的情况下。
2. `,` + num : 切换当前窗口到第 num 个 buffer
3. `<Space>` `b` `c` 关闭其他已经保存的 buffer 

#### navigate
1. 利用[LeaderF](https://github.com/Yggdroot/LeaderF) 快速搜索file，buffer，function 等。搜索文件使用 `,` `s` + 文件名, 同样的，搜索 buffer 的方法类似 : `,` `b` + buffer 名称。
![搜索文件](https://upload-images.jianshu.io/upload_images/9176874-2c447589c614dbed.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

2. 利用 [vista](https://github.com/liuchengxu/vista.vim) 实现函数侧边栏导航(类似于tagbar) ，打开关闭的快捷键 `<F2>`。

![导航栏](https://upload-images.jianshu.io/upload_images/9176874-59005a8b32a8b22e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

3. vista 和 LeaderF 都提供了函数搜索功能，被我映射为: `Space` `s` `f` 和 `Space` `s` `F` 
```vim
    call SpaceVim#custom#SPC('nnoremap', ['s', 'f'], 'Vista finder', 'search symbol with Vista ', 1)
    call SpaceVim#custom#SPC('nnoremap', ['s', 'F'], 'LeaderfFunction!', 'search symbol with LeaderF', 1)
```
其实它们的功能不限于搜索函数，比如搜索 markdown 的标题

#### define reference
这些功能都是lsp提供的，详细的配置在 plugin/coc.vim 中间，此处列举常用的。

1. `g` `d` : 跳转到定义
2. `g` `r` : 当只有一个 ref 的时候，直接跳转，当存在多个的时候，显示如下窗口，可以逐个选择:
![查找引用](https://upload-images.jianshu.io/upload_images/9176874-47415692f924d0c8.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

#### comment
在需要查询的函数或者变量上 : `K`，注释将会显示在悬浮窗口上。

![查找注释](https://upload-images.jianshu.io/upload_images/9176874-7d4916f3766ee4b8.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

#### documentation
在需要查询的函数上 : `Ctrl` `]`，相关文档将会显示在窗口上方。使用本功能需要安装[cppman](https://github.com/aitjcize/cppman) 以及缓存文档。
```
pip install cppman
cppman -c
```

![查找`get_id`文档](https://upload-images.jianshu.io/upload_images/9176874-640596fe5a653d60.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

和`查找注释`的功能区别在于，`K`是找到该函数的定义，然后显示函数或者变量"附近"(函数上方或者变量右侧的注释)，而查找文档是从 http://cplusplus.com/ 和 http://cppreference.com/ 中间获取文档。

#### snippet
基于[UltiSnips](https://github.com/SirVer/ultisnips/blob/master/doc/UltiSnips.txt) 可以自己向 UltiSnips/c.snippets，UltiSnips/cpp.snippets 中间添加 C/C++ 的自己定义代码段。 以前刷OJ的时候每次都不知道要加入什么头文件，然后就写了一个自定义 snippet，一键加入所有常用的头文件。

```snippets
snippet import
#include <iostream>
// 省略部分头文件，具体内容在下方的截图中间
#include <unordered_map>

using namespace std;

int main(){
	${0}
	return 0;
}
endsnippet
```

这样，然后每次只需要输入 import 这些内容就自动出现了，效果如下。
![此时只需要按下Enter，这些内容就会自动出现](https://upload-images.jianshu.io/upload_images/9176874-50be9343756e731f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

一般的自动补全, coc.nvim 无需另外的配置，效果如下。
![自动补全](https://upload-images.jianshu.io/upload_images/9176874-daac0f5b05792dba.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

#### git
SpaceVim 的[git layer](https://spacevim.org/layers/git/) 对于 git 的支持非常好，其相关的快捷键都是 `<Space>` `g` 开头的，非常好用。

在此基础上，我添加两个小功能:
1. [lazygit](https://github.com/jesseduffield/lazygit)，利用 [floaterm](https://github.com/voldikss/vim-floaterm)，在vim 中间运行 lazygit。
2. [GitMessenger](https://github.com/voldikss/vim-floaterm)可以显示所在行的 git blame 信息。
```vim
    call SpaceVim#custom#SPC('nnoremap', ['g', 'm'], 'GitMessenger', 'show commit message in popup window', 1)
    call SpaceVim#custom#SPC('nnoremap', ['g', 'l'], 'FloatermNew lazygit', 'open lazygit in floaterm', 1)
```

#### format
`Space`  `r`  `f` 格式化当前文件，支持C/C++ , Rust 和 Python 等。

可以通过一个工程的目录下的 `.clang-format` 来实现配置 C/C++ 的格式样式:
1. https://github.com/MaskRay/ccls/blob/master/.clang-format : 将代码格式为 LLVM 风格
2. https://github.com/torvalds/linux/blob/master/.clang-format : 代码格式为 linux kernel 风格

也可配置 google-style:
https://zhuanlan.zhihu.com/p/137840336 : 配置代码风格为 Google 风格

#### refactor之rename
有时候，写了一个函数名，然后多次调用，最后发现函数名的单词写错了，一个个的修改非常的让人窒息。使用 `,` `r` `n` 在需要重命名的元素上，即可批量重命名。

#### debug
关于vim如何集成gdb，现在存在非常多的插件，我没有仔细研究。我个人平时使用下面两个项目辅助 gdb 的使用:
1. https://github.com/cyrus-and/gdb-dashboard
2. https://www.gdbgui.com/

更多的参考 : https://scattered-thoughts.net/writing/the-state-of-linux-debuggers/

#### terminal
利用 `voidkiss/folaterm` 可以实现将终端以float window的形式打开，映射的快捷键分别为:
- `Ctrl` `n` : 创建新的 terminal window
- `Ctrl` `h` : 切换到 `prev` 的 terminal window
- `Ctrl` `l` : 切换到 `next` 的 terminal window
- `Fn5` : 显示/隐藏窗口

下面是在打开悬浮终端，并且运行 htop 的结果:
![floaterm](https://upload-images.jianshu.io/upload_images/9176874-32e6bbbc08cb4b8c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



## 扩展
需要说明的是，本配置并不局限于C/C++。由于 SpaceVim 的 layer 和 coc.nvim 的 extension，将上述内容可以非常容易迁移到其他类型的工作上。

#### 基于SpaceVim的扩展 以Latex为例子
- 如何扩展

在 init.toml 中间添加
```toml
[[layers]]
  name = "lang#latex"
```

- 效果

`Space` `l` `l` 启动编译， 保存的时候，自动更新，并且更新输出到 zathura 中间。
![使用 zathura 预览](https://upload-images.jianshu.io/upload_images/9176874-b51f76620f214709.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

- 原理

SpaceVim 的强大之处是将众多插件融合在一起，当使能 latex layer，那么 spacevim 会自动让包管理器安装 [vimtex](https://github.com/lervag/vimtex)，并且重新映射快捷键。
看一下其[文档](https://spacevim.org/layers/lang/latex/)和[源码](https://github.com/SpaceVim/SpaceVim/blob/master/autoload/SpaceVim/layers/lang/latex.vim)就非常清楚了。

- 说明

如果想要书写中文，需要修改默认的 latex engine，在 ~/.latexmkrc 中设置:
```
$pdf_mode = 5; 
```
参考:
- https://tex.stackexchange.com/questions/429274/chinese-on-mactex2018-simple-example
- https://tex.stackexchange.com/questions/501492/how-do-i-set-xelatex-as-my-default-engine

#### 基于coc.nvim的扩展 以Python为例
- 如何扩展

添加 coc-python 这个插件，并且启用微软的 python language server，也就是 disable 掉 jedi, 这一步是**必须的**，jedi 我从来没有正常成功使用过，总是崩溃。
```vim
let s:coc_extensions = [
			\ 'coc-python',

call coc#config("python.jediEnabled", v:false)
```

- 效果

![查找引用](https://upload-images.jianshu.io/upload_images/9176874-f759cf59365d5c57.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![查找](https://upload-images.jianshu.io/upload_images/9176874-773f3dabb59d0b97.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

- 原理

s:coc_extensions 添加 coc-python 之后，会自动安装[coc-python](https://github.com/neoclide/coc-python)和[language server](https://github.com/microsoft/python-language-server)。
通过coc.nvim，nvim 可以将自己伪装成为 vscode，coc-python 本身也是 vscode 的插件。如此，vscode 的处理 python 的技术被吸收到 vim 中来。

## [本配置]解释
SpaceVim 的文档往往是过时的或者是不详细的，直接阅读代码往往是更加好的方法，比如如果想知道 defx 的使用方法，进入到 ~/.SpaceVim/ 中，找到 defx.vim 直接阅读代码即可。

本配置的主要组成:
1. init.toml : 最基本的配置，在此处可以自己添加新的插件, SpaceVim加载后会加载此配置。不支持vim script.
2. autoload/myspacevim.vim : 一些插件的配置和快捷键, 支持vim script. 实现在init.toml中定义的bootstrap_before和bootstrap_after函数。
3. plugin/coc.vim : coc.nvim 和 ccls 的配置，几乎是[coc.nvim 标准配置](https://github.com/neoclide/coc.nvim#example-vim-configuration) 和 [ccls 提供给coc.nvim 的标准配置](https://github.com/MaskRay/ccls/wiki/coc.nvim) 的复制粘贴。
4. plugin/defx.vim : 添加了一条让 defx 忽略各种二进制以及其他日常工作中间不关心的文件。

一些快捷键的说明:
1. `<Space>`  `l`  `p` 预览markdown

## vim 的小技巧
1. 翻滚屏幕
```
# 保持所在行不动，移动屏幕
zz
zt
zb

# 移动屏幕内容
Ctrl + f - 向前滚动一屏，但是光标在顶部
Ctrl + d - 向前滚动一屏，光标在屏幕的位置保持不变
Ctrl + b - 向后滚动一屏，但是光标在底部
Ctrl + u - 向后滚动半屏，光标在屏幕的位置保持不变
```
2. vim 下的 Man 命令打开的 manual 是带高亮和符号跳转的，比在终端中间直接使用 man 好多了
3. 在最后一行添加相同的字符 `Ctrl + v` `$` `A` `string appended`，[参考](https://stackoverflow.com/questions/594448/how-can-i-add-a-string-to-the-end-of-each-line-in-vim)。
4. 在 Esc 是 vim 中间使用频率非常高的键位，为了不让自己的左手小拇指被拉长，可以将 CapsLock 键映射为 Esc 键，一种修改方法为在 ~/.profile 中加入。这个方法存在一个小问题，就是需要打开一个终端窗口才可以加载这个，应为 .profile 在 login 的时候才会被执行一次。
```
setxkbmap -option caps:swapescape
```

## 其他的一些资源
- neovim build-in lsp 最近愈发的完善，[这个项目](https://github.com/glepnir/lspsaga.nvim)为 build-in lps 提供更加美观的 UI.
- [C/C++ 项目利用 include-what-you-use 来引入头文件](https://github.com/include-what-you-use/include-what-you-use)


#### 主题
1. [dracula](https://draculatheme.com/vim/) 目前感觉最好看的主题之一
2. [vimcolors](http://vimcolors.com/) vim主题网站

#### 框架
1. [exvim](https://exvim.github.io/)
2. [spf13-vim](https://github.com/spf13/spf13-vim)
3. [The Ultimate vimrc](https://github.com/amix/vimrc)
4. [NVCode](https://github.com/ChristianChiarulli/nvim) 基于 coc.nvim 的一个配置
