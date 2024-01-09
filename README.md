A journey to setting up my own personalized development environment<br/>
- list of cli tools
- mainly about themes

### Terminal to Editor
```js
+-------------------------------------------------+   +-------------------------------------------------+
|                 Terminal                        |   | Terminal Emulator                               |
+-------------------------------------------------+   +-------------------------------------------------+
| Shell                                           |   | +-------------------------------------------+   |
|                                                 |   | | Shell                                     |   |
|                                                 |   | +-------------------------------------------+   |
|                                                 |   | | +---------------------------------------+ |   |
|                                                 |   | | | Prompt                                | |   |
|                                                 |   | | |---------------------------------------| |   |
|                                                 |   | | |                                       | |   |
|                                                 |   | | |  Editor                               | |   |
| >_ Prompt vim(Editor)                           |   | | +---------------------------------------+ |   |
+-------------------------------------------------+   +-------------------------------------------------+

```

- terminal emulator: [windows terminal](https://github.com/microsoft/terminal)
- shell: zsh
  - prompt: [starship](https://github.com/starship/starship)
  - plugins
    - default configuration: [oh-my-zsh](https://github.com/ohmybash/oh-my-bash)
    - fd
    - fzf 
    - https://mike.place/2017/fzf-fd/
    - 
    - editing...
  - terminal/shell management: tmux (opt out yet)
  - CLI AI: [zsh_codex](https://github.com/tom-doerr/zsh_codex)
    - alternative: [AI Shell](https://github.com/BuilderIO/ai-shell)
- editor: [LazyVim(NeoVim Distro)](https://github.com/LazyVim/LazyVim)
  - plugins
    - plugin manager: [lazy.nvim](https://github.com/folke/lazy.nvim)
    - PluginA
    - PluginB
    - PluginC
    - ...
    - Libs/plugins/Aliases
      - search
      - suggestions
      - predefined aliases
    - Completion
- Editor
  - UI (Font, Theme)
  - Search files
  - File explorer
  - Code assist
    - LLM AI
    - LSP
      - Syntax highlight
      - Formatter
      - Linter
      - Auto completion
      - Error
      - Refactor
      - Navigation
  - Plugins
    - 줜나 많음

- command line suggestion
- command line auto complete
- search files
- autojump
- fasd
- KKKKJ

**sync dotfiles** ([chezmoi](https://github.com/twpayne/chezmoi))
- [ ] write script that syncs on config diff
- [ ] add to cron for regular update

**sync ubuntu packages**
- [ ] write app manifest and add dotfile
- [ ] write script that install all packages for automation

**vim**
- [x] <strike>vimrc customization</strike>
- [x] neovim + lazyvim plugins
- [ ] organize nvim plguins and their basic usages
- [ ] add telescope extensions

**bash**
- [x] custom bash prompt
- [ ] see bash plugins usages and enable
