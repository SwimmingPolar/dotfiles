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

- **terminal emulator**: [windows terminal](https://github.com/microsoft/terminal)
- **shell**: zsh
  - **prompt**: [starship](https://github.com/starship/starship)
  - plugins
    - [wslu, ubuntu-wsl](https://wslutiliti.es/wslu/install.html)
    - default configuration: [oh-my-zsh](https://github.com/ohmybash/oh-my-bash)
    - search files [(fd+fzf)](https://mike.place/2017/fzf-fd/)
    - [zsh-completions](https://github.com/zsh-users/zsh-completions)
    - [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
    - editing...
  - terminal/shell management: tmux (opt out yet)
  - CLI AI: [zsh_codex](https://github.com/tom-doerr/zsh_codex)
    - alternative: [AI Shell](https://github.com/BuilderIO/ai-shell)
- **editor**: [LazyVim(NeoVim Distro)](https://github.com/LazyVim/LazyVim)
  - plugins
    - plugin manager: [lazy.nvim](https://github.com/folke/lazy.nvim)
    - multi cursor
    - PluginB
    - PluginC
    - ...
    - Libs/plugins/Aliases
      - search
      - suggestions
      - predefined aliases



  
- using .vimrc on nvim(neovim)'s init.lua
- image and theme colors not matching (termguicolors)
- (host browser inside wsl)[https://superuser.com/questions/1262977/open-browser-in-host-system-from-windows-subsystem-for-linux]



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
