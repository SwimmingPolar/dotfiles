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

- Terminal Emulator: [windows terminal](https://github.com/microsoft/terminal)
- Shell: zsh
  - 
  - Prompt: [starship](https://github.com/starship/starship)
  - Plugins:
    - Plugin manager/lib: [oh-my-zsh](https://github.com/ohmybash/oh-my-bash)
    - PluginA
    - PluginB
    - ...
  - Terminal/Shell Management: tmux (opt out yet)
  - LLM AI: [AI Shell](https://github.com/BuilderIO/ai-shell)
- Editor: [neovim](https://github.com/neovim/neovim)
  - Plugins:
    - Plugin manager/lib: [lazy.nvim](https://github.com/folke/lazy.nvim)
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
