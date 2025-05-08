# Script: PipeWire with WirePlumber

A [Polybar module](https://github.com/polybar/polybar-scripts) for displaying and controlling audio output information on systems using Pipewire.

## Motivation

Recent versions of Ubuntu (and Fedora) have replaced PulseAudio with Pipewire.
This is largely transparent to end users thanks to the `pipewire-pulse` compatibility layer provided by PipeWire.
However, interacting with the PulseAudio compatibility layer through tools like `pactl` and `pamixer` requires these to be installed, which is no longer automatically the case.

While other Polybar modules continue to assume the use of tools leveraging the PulseAudio API, this module does **not** make this assumption.
Instead, it relies on WirePlumber, which is the default session manager for PipeWire.

The key motivation for this Polybar module is avoiding the need to install additional dependencies.

## Dependencies

* `wpctl`

On recent Ubuntu systems, `wpctl` and ALSA should already be installed.
`wpctl` should be available through the package `wireplumber`, which is a dependency of `pipewire-audio`.
ALSA comprises multiple packages and will be installed along with `pipewire-alsa`.
