#!/usr/bin/env bash

function main () {
    case $1 in
        mute)
            wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
            ;;
        up)
            wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%+
            ;;
        down)
            wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%-
            ;;
        *)
            ;;
    esac

    # Volume & mute status comes from WirePlumber.
    local volume_and_mute=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | sed 's|^.*0\.||')
    local volume=$( echo ${volume_and_mute} | sed 's|^\([[:digit:]]\+\).*$|\1|')
    local muted=$( echo ${volume_and_mute} | grep -o MUTE )

    # WirePlumber does not seem to expose jack connection status, so extract from ALSA state.
    local headphone_switch=$(
        cat '/proc/asound/card0/codec#0' \
            | sed -rn '/name="Headphone Playback Switch/,/^Node/ { s/^\s+Amp-Out vals:\s+\[(.*)\]/\1/p }' \
            | cut -d' ' -f1
    )
    local speaker_volume=$(
        cat '/proc/asound/card0/codec#0' \
            | sed -rn '/name="Speaker Playback Volume/,/^Node/ { s/^\s+Amp-Out vals:\s+\[(.*)\]/\1/p }' \
            | cut -d' ' -f1
    )

    # Infer overall state and select appropriate glyph/symbol.
    local symbol
    if [[ $headphone_switch -eq '0x00' ]]; then
        # Headphones connected and on
        symbol='󰋋'
    elif [[ $speaker_volume -eq '0x00' ]] && [[ -n $muted ]]; then
        # Headphones connected but muted; awkward to infer.
        symbol='󰟎'
    elif [[ -n $muted ]]; then
        # Speakers muted.
        symbol='󰖁'
    else
        # Speakers on.
        symbol='󰕾'
    fi

    echo "%{T3}${symbol}%{T-} ${volume} "
}

main "$@"
