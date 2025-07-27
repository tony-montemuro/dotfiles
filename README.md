# dotfiles

User configuration files managed by [chezmoi](https://www.chezmoi.io/).

These configuration files are designed to work with two types of systems:

- A laptop (or single screen setup)
- A desktop, with two monitors

As a warning, I configured my system without any consideration for anyone else. Therefore, there is a **high probability** these dotfiles will not work with your setup!

## Setup

- [chezmoi](https://www.chezmoi.io/) is an obvious requirement. Please follow their documentation on installation, and connecting to this repository.
- You also will need to create a chezmoi configuration file:

```bash
touch ~/.config/chezmoi/chezmoi.toml
```

Here is a sample `chezmoi.toml` file, from my desktop:

```
[data]
	gap_size = 10

	[data.device]
	wired = "enp4s0"

		[data.device.wireless]
		enabled = false

		[data.device.battery]
		enabled = false

	[data.multihead]
	enabled = true

        # Not necessary if enabled = false
		[data.multihead.primary]
		name = "primary"
		resolution = 1920

        # Not necessary if enabled = false
		[data.multihead.secondary]
		name = "DP-2"
		resolution = 2560

	[data.theme]
	color = "blue"
```

Eventually, I would like to configure chezmoi to setup this configuration file on install, as well as install all configured software on installation. That could be a fun weekend project.
