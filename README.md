개발 프로세스에 관련이 있다기 보다는 개발 환경에서 사용되는<br/>
개인 도구들을 어디까지, 어떻게, 무엇을 사용해서 커스터마이징 가능한지<br/>
정리하고 설정 파일을 정리하는 중

### 보통 개발 환경에 필요한 도구
```js
+-------------------------------------------------+     +-------------------------------------------------+
|                 Terminal                        |     | Terminal Emulator                               |
+-------------------------------------------------+     +-------------------------------------------------+
| Shell                                           |     | +-------------------------------------------+   |
|                                                 |     | | Shell                                     |   |
|                                                 |     | +-------------------------------------------+   |
|                                                 |     | | +---------------------------------------+ |   |
|                                                 |     | | | Prompt                                | |   |
|                                                 |     | | |---------------------------------------| |   |
|                                                 |     | | |                                       | |   |
|                                                 |     | | |  Editor                               | |   |
| >_ Prompt vim(Editor)                           |     | | +---------------------------------------+ |   |
+-------------------------------------------------+     +-------------------------------------------------+
```

- Terminal Emulator
  - UI (font, color)
- Shell
  - Prompt
    - UI (color)
    - formatted text for various situations
  - Utilities
    - Libs/plugins/Aliases
      - search
      - suggestions
      - predefined aliases
    - Completion
  - Terminal/Shell Management
  - LLM AI
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
