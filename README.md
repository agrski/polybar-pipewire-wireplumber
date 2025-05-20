# Script: PipeWire with WirePlumber

A [Polybar module](https://github.com/polybar/polybar-scripts) for displaying and controlling audio output information on systems using Pipewire.

## Motivation

Recent versions of Ubuntu (and Fedora) have replaced PulseAudio with Pipewire.
This is largely transparent to end users thanks to the `pipewire-pulse` compatibility layer provided by PipeWire.
However, interacting with the PulseAudio compatibility layer through tools like `pactl` and `pamixer` requires these to be installed, which is no longer automatically the case.

While other Polybar modules continue to assume the use of tools leveraging the PulseAudio API, this module does **not** make this assumption.
Instead, it relies on WirePlumber, which is the default session manager for PipeWire, and to a lesser extent ALSA.

The key motivation for this Polybar module is avoiding the need to install additional dependencies.

## Key features

* Minimal dependencies.
* Use of IPC instead of polling for efficiency.
* Ability to change volume and mute/unmute via mouse actions.
* Output device (headphones or speakers) displayed in module.

## Dependencies

* `wpctl`
* `acpid`
* `enable-ipc = true` in Polybar config

On recent Ubuntu systems, `wpctl` and ALSA should already be installed.
`wpctl` should be available through the package `wireplumber`, which is a dependency of `pipewire-audio`.
ALSA comprises multiple packages and will be installed along with `pipewire-alsa`.

The ACPI subsystem (via package `acpid`) may need to be installed.

As this module uses IPC, Polybar must be configured to use this with `enable-ipc = true` in your `config.ini`.

## Module

```ini
[module/pipewire]
type = custom/ipc

hook-0 = ~/polybar-scripts/pipewire.sh
hook-1 = ~/polybar-scripts/pipewire.sh mute
hook-2 = ~/polybar-scripts/pipewire.sh up
hook-3 = ~/polybar-scripts/pipewire.sh down
hook-4 = sleep 1 && ~/.config/polybar/scripts/pipewire.sh
initial = 5

click-left = "#pipewire.hook.1"
scroll-up = "#pipewire.hook.2"
scroll-down = "#pipewire.hook.3"

label = " %output% "
format = <label>
```

<details>
    <summary>Explanation of module options</summary>

    This module expects the use of IPC.

    Each of its hooks correspond to options in the bash script `pipewire.sh`.
    Every invocation of this script will return a string formatted with [lemonbar tags](https://github.com/polybar/polybar/wiki/Formatting#format-tags), but it will also perform the specified action if one is provided.
    If an action is unrecognised, the script will not error but instead just return the current state of the default audio sink -- be careful with typos!

    The final hook, `hook-4`, is the same as `hook-0` but with an initial sleep so that Polybar can load properly before it is called.
    Without this, the module will not format properly until an action triggers it to reload.
    You can change the `sleep 1` to something larger, e.g. `sleep 5`, if you are having difficulty with this.

    The variable `initial` is a one-indexed hook selector to run when Polybar starts, as described in [the docs](https://github.com/polybar/polybar/wiki/Module:-ipc#basic-settings).
    In this case, `initial = 5` means run `hook-4` on initialisation.

    The script uses lemonbar tags because it is responsible for formatting the full module output -- Polybar is not flexible enough to support one or more script outputs which can then be stitched together with icons and spacing.
    (Correct me if I am wrong about this!)
    If you want/need to change the icons, e.g. because they do not render in your chosen font(s), you **must** update the script `pipewire.sh`.
</details>

Screenshots of the four different module states using icons from Iosevka Nerd Font Mono:

![speakers unmuted](./screenshots/polybar_pipewire_speakers_unmuted.png)
![speakers muted](./screenshots/polybar_pipewire_speakers_muted.png)
![headphones unmuted](./screenshots/polybar_pipewire_headphones_unmuted.png)
![headphones muted](./screenshots/polybar_pipewire_headphones_muted.png)

The following mouse gestures are supported:
* increase & decrease volume with mouse scroll wheel,
* toggle mute with left mouse click.

You may bind your own behaviours to other mouse actions as per the [Polybar documentation](https://polybar.readthedocs.io/en/stable/user/actions.html).

The use of headphones or speakers is automatically detected, including when they are plugged in or unplugged, and communicated to Polybar using an ACPI trigger.
This requires `acpid` to be installed and certain scripts to be placed in the right locations and made executable:
* [`headphones_acpi_handler.sh`](./headphones_acpi_handler.sh) can be placed anywhere, so long as [`headphones_acpi_trigger`](./headphones_acpi_trigger) is updated to point to the right location; it must be made executable, e.g. with `chmod +x headphones_acpi_handler.sh`.
* [`headphones_acpi_trigger`](./headphones_acpi_trigger) should be copied to the directory `/etc/acpi/events`; it does not need to be executable.

The trigger filters ACPI events for only those concerning the headphone jack and invokes the handler.
The handler uses IPC (`polybar-msg`) to inform all running bars of the headphones being (un)plugged.
This setup is a bit fiddly because the ACPI daemon runs as root, but Polybar is probably not running as root and `polybar-msg` only works between processes owned by the same user.
The trick to work around this is using the `XDG_RUNTIME_DIR` environment variable to specify the user information for IPC to work.
If you are **not** running as user ID 1000 (check with `id -u` or similar), you **must** update the handler script.

If you are not interested in using ACPI for detecting the change of output device, you can change the module type to `custom/script` and set a reloading `interval` instead.

## Caveats & considerations

### Formatting

As mentioned in the module explanation section, it is [pipewire.sh](./pipewire.sh) that is responsible for formatting the module outputs -- the volume level and icons.
This is done through the use of [lemonbar tags](https://github.com/polybar/polybar/wiki/Formatting#format-tags).

If the current formatting does not suit your font choices or style preferences, it is necessary to update `pipewire.sh` rather than being able to change module configuration.
For example, you may need to change the font tags (`{T...}`) to select the appropriate font(s).

### Inferring output device

This module, specifically the `pipewire.sh` script, searches in `/proc/asound` for a specific card (`card0` by default) and scrapes information from this.
It uses this to infer whether headphones or speakers are the output device and the mute status.
This works, but it feels awkward and brittle and inelegant to do so.
I have not, as yet, been able to find a better source of this information through the commands installed automatically with the `alsa` package.
If anyone is aware of how to do this more robustly, please do let me know!

### Detecting output device changes

Currently there is a single ACPI trigger defined for events concerning the headphone _jack_.
I am unsure how this would handle wireless devices such as Bluetooth headphones, but presume it would be necessary to:
* add a new trigger (trivial),
* possibly update the ALSA configuration scraping (probably non-trivial).

### Switching output device

It is not currently possible to switch the output device via a mouse action, e.g. from headphones to speakers.
It feels like this should be possible, as Gnome has this facility, so any advice would be appreciated!
I will look into adding this in the future, e.g. via the right-click action.

## Acknowledgements

This repository was inspired by [this Reddit thread](https://www.reddit.com/r/Polybar/comments/mt4f0r/just_switched_to_pipewire_for_audio_is_there_a/), specifically [victortrac's polybar-scripts module](https://github.com/polybar/polybar-scripts/pull/320/files) and the suggestion by `Decvai` to use IPC instead of polling.
