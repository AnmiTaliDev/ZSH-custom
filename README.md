# Custom ZSH Configuration Script

A powerful and customizable script for setting up your Zsh shell environment with Oh My Zsh.

## Features

- Interactive theme selection (10 popular themes)
- Custom editor selection
- Flexible plugin management
- Automatic backup of existing configurations
- Smart error handling and logging
- Support for custom local configurations

## Prerequisites

The following packages must be installed on your system:
- git
- curl
- zsh

## Quick Start

1. Clone this repository:
```bash
git clone [repository-url]
cd [repository-name]
```

2. Make the script executable:
```bash
chmod +x custom-zsh.sh
```

3. Run the script:
```bash
./custom-zsh.sh
```

## What the Script Does

1. **Backup**: Creates a backup of your existing `.zshrc` if it exists
2. **Oh My Zsh**: Installs Oh My Zsh if not already installed
3. **Theme Selection**: Offers 10 popular themes to choose from:
   - robbyrussell (default)
   - agnoster
   - powerlevel10k
   - spaceship
   - af-magic
   - bira
   - dallas
   - jonathan
   - candy
   - fino

4. **Editor Selection**: Lets you choose your preferred text editor
5. **Plugin Selection**: Installs basic plugins and lets you choose additional ones

### Basic Plugins (Included by Default)
- git
- fzf
- zsh-syntax-highlighting
- zsh-autosuggestions
- colorize
- command-not-found
- history-substring-search

### Additional Available Plugins
- kubectl
- npm
- pip
- python
- rust
- golang
- docker
- docker-compose
- terraform
- aws

## Configuration Files

- Main configuration: `~/.zshrc`
- Local customizations: `~/.zshrc.local`
- Backup of old config: `~/.zshrc.backup.[timestamp]`
- Log file: `/tmp/zsh_setup_[timestamp].log`

## Customization

### Local Configuration
Add your personal customizations to `~/.zshrc.local`. This file is automatically sourced and won't be overwritten by updates.

Example `~/.zshrc.local`:
```bash
# Custom aliases
alias myapp='cd ~/projects/myapp'
alias serve='python3 -m http.server'

# Custom environment variables
export MY_API_KEY="your-api-key"
```

## Troubleshooting

1. **Theme doesn't look right**: 
   - For themes like agnoster or powerlevel10k, install a Powerline-compatible font
   - Run `exec zsh` to reload the shell

2. **Plugin not working**: 
   - Check the log file in `/tmp/zsh_setup_[timestamp].log`
   - Ensure all prerequisites for the plugin are installed

3. **Command not found errors**: 
   - Ensure all required packages (git, curl, zsh) are installed
   - Run `source ~/.zshrc` or restart your terminal

## Support

For issues and feature requests, please create an issue in the repository.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Recent Updates

Last updated: 2025-02-08
Author: AnmiTaliDev

## Acknowledgments

- Oh My Zsh community
- All theme and plugin creators
- Contributors to this project
