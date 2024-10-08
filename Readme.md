# neovim及spacevim的C/C++配置 (适用于wsl2)


<details open="">
  <summary>目录</summary>
<!-- vim-markdown-toc GitLab -->

- [前言](#前言)
- [关于lsp和async](#关于-language-server-protocol-和-async)
- [安装](#install)
- [用于Linux Kernel](#work-with-linux-kernel)
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
- [配置解释](#本配置解释)
- [其他资源](#其他资源)


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
Neovim is a Vim-based text editor engineered for sibility and usability. 
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
|                 | custom的插件放在~/.cache/vimfiles目录.
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
Ubuntu18.04可以参考[Ubuntu18.04配置SpaceVim](https://blog.csdn.net/cs874300/article/details/108562173?utm_medium=distribute.pc_relevant.none-task-blog-BlogCommendFromMachineLearnPai2-2.control&depth_1-utm_source=distribute.pc_relevant.none-task-blog-BlogCommendFromMachineLearnPai2-2.control)
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
根据情况可能需要运行如下命令:
```
npm -g install neovim
```

在Ubuntu上安装最新版本的Neovim (nvim大于5.0的版本可能需要额外的配置，如可能内置了lsp等，暂未进行完整验证):
```
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x nvim.appimage
./nvim.appimage --appimage-extract
./squashfs-root/AppRun --version

# Optional: exposing nvim globally
mv squashfs-root / && ln -s /squashfs-root/AppRun /usr/bin/nvim
nvim --version
```

2. 按照Spacevim 安装的[官方文档](https://spacevim.org/cn/quick-start-guide/)安装SpaceVim。只为neovim安装Spacevim用:
```
curl -sLf https://spacevim.org/install.sh | bash -s -- --install neovim
```

3. 安装npm和yarn, **保证yarn/npm使用国内镜像, 部分插件需要使用yarn/npm安装, 如果不切换为国内镜像, ***很容易***出现安装失败.**，切换方法可搜索. 安装完成之后检查:
```
➜  Vn git:(master) ✗ yarn config get registry && npm config get registry
npm config set registry https://registry.npmmirror.com

如果遇到yarn配置报错, 需卸载cmdtest和yarn后通过npm重新安装yarn. sudo npm install -g yarn. 然后重启终端。
```

**安装最新版本的npm和nodejs方法**:
```
curl -LO https://nodejs.org/download/release/v15.14.0/node-v15.14.0-linux-x64.tar.gz
tar xvf node-v15.14.0-linux-x64.tar.gz
cd node-v15.14.0-linux-x64/bin
echo "export PATH=`pwd`:$PATH" >> ~/.profile
node -v
npm version
npm install -g npm@7.20.0
npm -g install neovim
```

https://github.com/nodejs/help/wiki/Installation
https://nodejs.org/en/download/


4. 安装ccls。也可以参考其[官方文档](https://github.com/MaskRay/ccls/wiki/Build)手动编译获取最新版。
```
➜  Vn git:(master) ✗ sudo apt install ccls
➜  Vn git:(master) ✗ ccls -version
ccls version 0.20190823.6-1~ubuntu1.20.04.1
clang version 10.0.0-4ubuntu1
```


手工编译posix版的ccls:

The simplest/quickest build with all defaults (only for POSIX systems) is:

Download "Pre-Built Binaries" from https://releases.llvm.org/download.html
 and unpack to /path/to/clang+llvm-xxx.
 Do not unpack to a temporary directory, as the clang resource directory is hard-coded
 into ccls at compile time!
 See https://github.com/MaskRay/ccls/wiki/FAQ#verify-the-clang-resource-directory-is-correct
```
curl -LO https://github.com/llvm/llvm-project/releases/download/llvmorg-12.0.0/clang+llvm-12.0.0-x86_64-linux-gnu-ubuntu-20.04.tar.xz
tar xvf clang+llvm-12.0.0-x86_64-linux-gnu-ubuntu-20.04.tar.xz

git clone --depth=1 --recursive https://github.com/MaskRay/ccls
cd ccls

cmake -H. -BRelease -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=./../clang+llvm-12.0.0-x86_64-linux-gnu-ubuntu-20.04
cmake --build Release

sudo cmake --install Release/ --prefix /usr/local/
```


Ubuntu 18.04 prebuilt binaries are actually suitable for many non-Ubuntu distributions. You may replace the last two cmake commands with:
```
wget -c http://releases.llvm.org/8.0.0/clang+llvm-8.0.0-x86_64-linux-gnu-ubuntu-18.04.tar.xz
tar xf clang+llvm-8.0.0-x86_64-linux-gnu-ubuntu-18.04.tar.xz
cmake -H. -BRelease -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=$PWD/clang+llvm-8.0.0-x86_64-linux-gnu-ubuntu-18.04
cmake --build Release

```

Ignore fatal: No names found, cannot describe anything message Proceed with cmake --build Release and, if successful, cd Release && sudo make install

The resulting executable will be Release/ccls. If you forgot to pass --recursive when cloning the repo, git submodule update --init to clone the rapidjson repository.

If you compile ccls with GCC 8.2.1, append -DCMAKE_CXX_FLAGS=-fno-gnu-unique. See https://github.com/MaskRay/ccls/issues/363#issuecomment-482625854 for details.

ld时缺库的话，可能需要执行如下命令来安装:
```
sudo apt-get install libz-dev  (改名叫lib1g-dev)
sudo apt-get install libtinfo-dev
```

如果不重新编译的话，可能ccls会找不到一些头文件如stddef.h, 原因按作者如下：
```
Clang resource directory
Some header files such as stddef.h stdint.h are located in the include/ subdirectory of Clang resource directory. The path is derived from clang -print-resource-dir at CMake configure time.

The location is hard-coded in the ccls executable (-DCLANG_RESOURCE_DIR= when building ccls). If you want to install ccls and delete the build directory, you need to copy the contents of the resource directory before building ccls.

Otherwise the absence of Clang resource directory may lead to errors like unknown type name 'size_t'.

sudo mkdir -p /usr/local/clang/7.0.0
sudo cp -a Release/clang+llvm-7.0.0-x86_64-linux-gnu-ubuntu-16.04/lib/clang/7.0.0/include /usr/local/clang/7.0.0/
Then you must set the initialization option clang.resourceDir: --init='{"clang": {"resourceDir": "/usr/local/clang/7.0.0"}}'.

note: It's likely you will encounter this issue whenever you update clang without rebuilding ccls.

Detai参考: https://github-wiki-see.page/m/MaskRay/ccls/wiki/Install#clang-resource-directory
```

5. 下载本配置(目录.SpaceVim.d), 在此基础上定制自己的配置。会使能coc和lsp.注意coc.nvim对nodej有版本要求, 需参考coc.nvim的github页来确认。
```sh
cd ~ # 保证在根目录
rm -r .SpaceVim.d # 将原来的配置删除
git clone https://github.com/messon007/My-Linux-config .SpaceVim.d 
nvim # 打开vim 将会自动安装所有的插件
```
init.toml
```
# All SpaceVim option below [option] section
[options]
    # set spacevim theme. by default colorscheme layer is not loaded,
    # if you want to use more colorscheme, please load the colorscheme
    # layer
    # colorscheme = "gruvbox"
    colorscheme = "dracula"
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
#        'major mode',
#        'filename',
#        'fileformat'
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
    enable_vimfiler_welcome = false

# Enable autocomplete layer
[[layers]]
    name = 'autocomplete'
    auto_completion_return_key_behavior = "complete"
    auto_completion_tab_key_behavior = "cycle"
    auto_completion_enable_snippets_in_popup = true
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

[[layers]]
    name = "edit"
    enable = false

# fuzzy search
[[layers]]
  name = "denite"
  enable = false

# fuzzy search
[[layers]]
  name = "fzf"
  enable = false

[[layers]]
    name = "cscope"
    enable = false

[[layers]]
    name = "gtags"
    gtagslabel = "pygments"
    enable = false

[[layers]]
    name = "ui"
    enable = false

# 基于lsp的高亮插件
#[[custom_plugins]]
#    name = 'jackguo380/vim-lsp-cxx-highlight'

# 主要用于快速搜索 文件, buffer 和 函数
[[custom_plugins]]
    name = "Yggdroot/LeaderF"
    build = "./install.sh"

# 参考https://vimjc.com/vim-indentLine-plugin.html
[[custom_plugins]]
    name = 'Yggdroot/indentLine'

# 从 http://cplusplus.com/ 和 http://cppreference.com/ 获取文档
[[custom_plugins]]
    name = 'skywind3000/vim-cppman'

[[custom_plugins]]
    repo = "dracula/vim"
    name = "dracula"
    merged = false
    
[[custom_plugins]]
    name = 'voldikss/vim-translator'
    
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
    let g:neomake_cpp_clang_args = ["-std=c++11", "-Wextra", "-Wall", "-fsanitize=undefined","-g"]
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

" 使用 Microsoft Python Language Server 不然 coc.nvim 会警告. coc-python才需要这个
" call coc#config("python.jediEnabled", v:false)

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

" coc.nvim 插件，用于支持 python 等语言, coc-python deprecated, use coc-pyright instead
let s:coc_extensions = [
      \ 'coc-pyright',
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

6. 启动nvim, 其会自动安装所需的插件。然后在nvim中执行 `checkhealth` 命令，其会提醒需要安装的各种依赖。比如 xclip 没有安装，那么和系统的clipboard和vim的clipboard之间复制会出现问题。neovim 的 python 的没有安装可能导致直接不可用。
安装的插件目录应该在.cache/vimfiles/repos/github.com/底下. 
```
sudo apt install xclip
# archlinux 请使用 wl-clipboard 替代xclip
# sudo pacman -S wl-clipboard
sudo pip3 install neovim
```
wsl2 linux下还需要安装x server(xming或vcxsrv), 参考https://github.com/Microsoft/WSL/issues/1069 或 https://gist.github.com/necojackarc/02c3c81e1525bb5dc3561f378e921541
通过"+y 和 "+p来进行复制和粘贴. 
当windows有多个IP时, 注意xming监听的127.0.0.1对应哪个ip.

7. 安装[bear](https://github.com/rizsotto/Bear)。ccls 需要通过 bear 生成的 compile_commands.json 来构建索引数据。
```
sudo apt install bear
```

注：使用 bear 生成 compile_commands.json 是一种通用的方法，但是不同的 build 工具和项目还存在一些捷径可走:
1. linux 内核使用自带的脚本 `scripts/clang-tools/gen_compile_commands.py`，具体可以参考[这里](https://patchwork.kernel.org/patch/10717125/)，这样的话就不用更改一次 .config 就重新编译整个内核。
2. cmake 生成 compile_commands.json, 只需在CMakeLists.txt中增加:
```
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
```
3. [ninja](https://ninja-build.org/manual.html)
```
ninja -t compdb > compile_commands.json
```
4. [ccls documentation for more](https://github.com/MaskRay/ccls/wiki/Project-Setup)

compile_commands.json需要放到项目root路径。(Provide compile_commands.json at the project root).

## Work with Linux Kernel
```
git clone https://mirrors.tuna.tsinghua.edu.cn/git/linux.git
cd linux
# 使用标准配置，参考 :  https://www.linuxtopia.org/online_books/linux_kernel/kernel_configuration/ch11s03.html
make ARCH=arm64 defconfig
# 编译内核
make ARCH=arm64 CROSS_COMPILE=aarch64-fsl-linux-- -j8
# 若报错，则:
sudo apt install libssl-dev
sudo apt install libelf-dev

# 在 xxx 之后的内核中间, 利用生成 compile_commands.json
scripts/clang-tools/gen_compile_commands.py
# 第一次打开的时候，ccls 会生成索引文件，此时风扇飞转属于正常现象，之后不会出现这种问题
nvim 
```
一个工程只要生成 compile_commands.json，那么一切就大功告成了。

## 基本操作
默认为vim兼容模式，详细的操作请移步到SpaceVim, coc.nvim, ccls 以及特定插件的文档。

注意: vim 默认的 leader 键(默认为\, 重定义为,)，加上windows_leader(默认为s, vim兼容模式下其不可用), space_leader, 一共存在三个 leader 键，其功能总结如下:
| `,`                         | `s`      | `Space`  |
|-----------------------------|----------|----------|
| 通用vim leader 键，有各种作用 | 窗口操作 | SpaceVim使用|

这三个键位都是可以重新映射的。
以下为 SpaceVim 中与 Vim 默认情况下的一些差异。但是设为vim兼容模式的话(vimcompatible = true )，下列差异都不存在。
按键 s 是删除光标下的字符，但是在 SpaceVim 中， 它是Normal模式窗口快捷键的前缀，这一功能可以使用选项 windows_leader 来修改，默认是 s。 如果需要使用按键 s 的原生功能，可以将该选项设置为空。
按键 , 是重复上一次的搜索 f、F、t 和 T ，但在 SpaceVim 中默认被用作为语言专用的前缀键。如果需要禁用此选项， 可设置 enable_language_specific_leader = false。


#### search
[vim-searchindex](https://github.com/google/vim-searchindex) 可以显示当前是第几个文本项.

spacevim 配置提供了强大的[异步搜索功能](https://spacevim.org/grep-on-the-fly-in-spacevim/), 比较常用的是:

| key binding     | function                                  |
|-----------------|-------------------------------------------|
| `Space` `s` `/` | 实时动态搜索(grep on the fly)             |
| `Space` `s` `p` | 搜索整个工程                              |
| `Space` `s` `b` | 搜索所有打开的 buffer                     |
| `Space` `s` `P` | **对于光标所在字符**搜索整个工程          |
| `Space` `s` `B` | **对于光标所在字符**搜索所有打开的 buffer |

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
如果报错, 可能需要执行pip3 install pynvim.

#### window
窗口管理
常用的窗口管理快捷键有一个统一的前缀，默认的前缀 [Window] 是按键 s，可以在配置文件中通过修改 SpaceVim 选项 window_leader 的值来设为其它按键：
[options]
    windows_leader = "s"

vim兼容模式下需用vim的窗口管理快捷键.

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
使能该快捷键需要使用如下配置:
autocmd FileType c,cpp noremap <C-]> <Esc>:execute "Cppman " . expand("<cword>")<CR>

![查找`get_id`文档](https://upload-images.jianshu.io/upload_images/9176874-640596fe5a653d60.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

和`查找注释`的功能区别在于，`K`是找到该函数的定义，然后显示函数或者变量"附近"(函数上方或者变量右侧的注释)，而查找文档是从 http://cplusplus.com/ 和 http://cppreference.com/ 中间获取文档。

#### snippet
代码块引擎
默认的代码块引擎插件使用的是 neosnippet，可以通过 SpaceVim 选项 snippet_engine 来修改为 ultisnips。

[options]
    snippet_engine = "ultisnips"
默认情况下，会自动载入以下代码块仓库的代码块模板：

Shougo/neosnippet-snippets：neosnippet 的默认代码块模板
honza/vim-snippets：额外的代码块模板
如果 snippet_engine 是 neosnippet，以下文件夹内的代码块模板会被载入：

~/.SpaceVim/snippets/：SpaceVim 内置代码块模板
~/.SpaceVim.d/snippets/：用户全局代码块模板
./.SpaceVim.d/snippets/：当前项目本地代码块模板
你也可以在启动函数内通过变量 g:neosnippet#snippets_directory 添加额外的文件夹， 该变量的值可以是一个 string，指定文件夹路径，也可是一个 list， 其内，每一个元素指定一个文件夹路径。

如果 snippet_engine 是 ultisnips，以下文件夹内的代码块模板会被载入：

~/.SpaceVim/UltiSnips/：SpaceVim 内置代码块模板
~/.SpaceVim.d/UltiSnips/：用户全局代码块模板
./.SpaceVim.d/UltiSnips/：当前项目本地代码块模板
默认情况下，代码块模板缩写词会在补全列表里面显示，以提示当前输入的内容为一个代码块模板的缩写， 如果需要禁用这一特性，可以设置 auto_completion_enable_snippets_in_popup 为 false。

[[layers]]
  name = "autocomplete"
  auto_completion_enable_snippets_in_popup = false

可以自己向 c.snippets，cpp.snippets 中间添加 C/C++ 的自己定义代码段。 
```snippets
snippet header
#include <iostream>
// 省略部分头文件，具体内容在下方的截图中间
#include <unordered_map>

using namespace std;

endsnippet
```

这样，然后每次只需要输入 header 这些内容就自动出现了，效果如下。
![此时只需要按下Enter，这些内容就会自动出现](https://upload-images.jianshu.io/upload_images/9176874-50be9343756e731f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

一般的自动补全, coc.nvim 无需另外的配置，效果如下。
![自动补全](https://upload-images.jianshu.io/upload_images/9176874-daac0f5b05792dba.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

实际测试该配置还不能用。

#### git
SpaceVim 的[git layer](https://spacevim.org/layers/git/) 对于 git 的支持非常好，其相关的快捷键都是 `<Space>` `g` 开头的，非常好用。

在此基础上，我添加两个小功能:
1. [lazygit](https://github.com/jesseduffield/lazygit)，利用 [floaterm](https://github.com/voldikss/vim-floaterm)，在vim 中间运行 lazygit。
2. [GitMessenger](https://github.com/voldikss/vim-floaterm)可以显示所在行的 git blame 信息。
```vim
    call SpaceVim#custom#SPC('nnoremap', ['g', 'm'], 'GitMessenger', 'show commit message in popup window', 1)
    call SpaceVim#custom#SPC('nnoremap', ['g', 'l'], 'FloatermNew lazygit', 'open lazygit in floaterm', 1)
```

#### shell
SpaceVim 支持两种 shell，用户在启用该模块时，可以通过 default_shell 这一模块选项来指定默认的 shell 工具。
terminal：使用 Vim/Neovim 内置终端
VimShell：使用 VimShell 这一插件
The default shell is quickly accessible via a the default shortcut key SPC '.
SPC '	打开或跳至已打开的终端窗口
Ctrl-d	输入模式下关闭终端窗口
q	Normal 模式下隐藏终端窗口
<Esc>	从 Terminal 模式切换到 Normal 模式
Ctrl-Left	切换到左侧窗口
Ctrl-Up	切换到上方窗口
Ctrl-Down	切换到下方窗口
Ctrl-Right	切换到右侧窗口

#### format
:Format格式化当前文件，支持C/C++ , Rust 和 Python 等。

可以通过一个工程的目录下的 `.clang-format` 来实现配置 C/C++ 的格式样式:
1. https://github.com/MaskRay/ccls/blob/master/.clang-format : 将代码格式为 LLVM 风格
2. https://github.com/torvalds/linux/blob/master/.clang-format : 代码格式为 linux kernel 风格

也可配置 google-style:
https://zhuanlan.zhihu.com/p/137840336 : 配置代码风格为 Google 风格

#### refactor之rename
使用SP + l + e可实现rename.

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

## [本配置](https://github.com/messon007/My-Linux-config)解释
阅读SpaceVim里plugin代码如defx: 进入 ~/.SpaceVim/ 中，找到 defx.vim 直接阅读代码即可。

本配置的主要组成:
0. nvim会加载~/.config/nvim/目录下的init.vim。SpaceVim定制了init.vim. SpaceVim会加载~/.SpaceVim.d/
1. init.toml: SpaceVim最基本的配置，在此处可以自己添加新的插件, SpaceVim加载后会加载此配置。不支持vim script.
2. autoload/myspacevim.vim : 一些插件的配置和快捷键, 支持vim script. 实现在init.toml中定义的bootstrap_before和bootstrap_after函数。
3. plugin/coc.vim : coc.nvim 和 ccls 的配置，几乎是[coc.nvim 标准配置](https://github.com/neoclide/coc.nvim#example-vim-configuration) 和 [ccls 提供给coc.nvim 的标准配置](https://github.com/MaskRay/ccls/wiki/coc.nvim) 的复制粘贴。
4. plugin/defx.vim : 添加了一条让 defx 忽略各种二进制以及其他日常工作中间不关心的文件。
5. 下载的插件缓存在~/.cache/vimfiles中.
6. SpaceVim默认设置在~/.SpaceVim/autoload/SpaceVim/default.vim. 启动会先先执行里面的设置, 再执行custom.vim即.SpaceVim.d/init.toml中的定制.
7. coc.nvim是conquer of completion, 期望给neovim/vim提供vscode类似体验, 有丰富的生态体系，也是一个框架。默认不带语言服务器，支持各种语言服务器插件。

## 实现语言
- neovim: C, vimscript(vimL), lua
- SpaceVim: viml (插件管理器，有了coc, SpaceVim用处不大, 可移除)
- coc.nvim: viml + nodejs(通过rpc和viml进行通信. coc/rpc.vim中的start_server->job_command->node进程)
- coc-pyright: coc的python语言服务器. 从vscode版的pyright演化而来.

## 其他资源
- neovim build-in lsp 最近愈发的完善，[这个项目](https://github.com/glepnir/lspsaga.nvim)为 build-in lps 提供更加美观的 UI.
- [C/C++ 项目利用 include-what-you-use 来引入头文件](https://github.com/include-what-you-use/include-what-you-use)
- https://neovim.io/doc/user/vim_diff.html#vim-differences
- [ubuntu18.04安装vim 8.2](https://www.linuxidc.com/Linux/2020-03/162590.htm)

#### 主题
1. [dracula](https://draculatheme.com/vim/) 目前感觉最好看的主题之一

#### 框架
1. [exvim](https://exvim.github.io/)
2. [spf13-vim](https://github.com/spf13/spf13-vim)
3. [The Ultimate vimrc](https://github.com/amix/vimrc)
4. [NVCode](https://github.com/ChristianChiarulli/nvim) 基于 coc.nvim 的一个配置

#### vim 的小技巧
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
