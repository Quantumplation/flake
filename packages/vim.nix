{ pkgs, ... }: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    plugins = with pkgs.vimPlugins; [
      # File navigation
      nerdtree
      fzf-vim
      vim-vinegar  # Enhanced netrw

      # Syntax highlighting and language support
      vim-nix
      vim-toml
      rust-vim
      vim-go
      typescript-vim
      vim-javascript
      vim-jsx-typescript
      haskell-vim
      vim-markdown

      # Lean 4
      lean-nvim
      nvim-lspconfig
      plenary-nvim

      # Aiken support (Cardano smart contracts)
      (pkgs.vimUtils.buildVimPlugin {
        name = "aiken-vim";
        src = pkgs.fetchFromGitHub {
          owner = "aiken-lang";
          repo = "editor-integration-nvim";
          rev = "master";
          sha256 = "sha256-1JlJlNfMmn2/BIz8rzy5+VJZ2gnjmxAiIG6Q5pB/ZDY=";
        };
      })

      # Editor enhancements
      vim-surround      # Easily change surrounding quotes/brackets
      vim-commentary    # Easy commenting with gc
      vim-repeat        # Make . work with plugins
      vim-fugitive      # Git integration
      vim-gitgutter     # Show git diff in gutter
      vim-airline       # Status line
      vim-airline-themes

      # Color schemes
      tokyonight-nvim
      gruvbox
    ];

    extraLuaConfig = ''
      require('lean').setup({
        lsp = {},
        mappings = true,
      })
    '';

    extraConfig = ''
      " Basic settings
      set number relativenumber
      set expandtab tabstop=2 shiftwidth=2 softtabstop=2
      set autoindent smartindent
      set ignorecase smartcase
      set incsearch hlsearch
      set hidden
      set mouse=a
      set clipboard=unnamedplus
      set splitbelow splitright
      set cursorline
      set scrolloff=8
      set signcolumn=yes
      set updatetime=300
      set undofile
      set termguicolors

      " Color scheme
      colorscheme tokyonight

      " Leader key
      let mapleader = " "

      " NERDTree
      nnoremap <leader>n :NERDTreeToggle<CR>
      nnoremap <leader>f :NERDTreeFind<CR>
      let NERDTreeShowHidden=1

      " FZF
      nnoremap <leader>p :Files<CR>
      nnoremap <leader>g :Rg<CR>
      nnoremap <leader>b :Buffers<CR>

      " Quick save and quit
      nnoremap <leader>w :w<CR>
      nnoremap <leader>q :q<CR>

      " Better window navigation
      nnoremap <C-h> <C-w>h
      nnoremap <C-j> <C-w>j
      nnoremap <C-k> <C-w>k
      nnoremap <C-l> <C-w>l

      " Clear search highlight
      nnoremap <leader><CR> :nohlsearch<CR>

      " Airline
      let g:airline_powerline_fonts = 1
      let g:airline#extensions#tabline#enabled = 1

      " Git gutter
      let g:gitgutter_sign_added = '+'
      let g:gitgutter_sign_modified = '~'
      let g:gitgutter_sign_removed = '-'
    '';
  };
}
