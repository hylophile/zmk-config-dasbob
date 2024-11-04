default:
    @just --list --unsorted

keyboard := "dasbob"
automounted_as := "NICENANO"
export zmk_board := "nice_nano_v2"
export zmk_shield := "dasbob_left"
flash_target_dir := "/run/media" / env('USER') / automounted_as
nametag := zmk_shield + "_firmware"

# build firmware and flash it
flash: build
    #!/usr/bin/env bash
    set -euo pipefail
    printf "Flashing: Looking for '{{ flash_target_dir }}'."
    for i in {1..30}
    do
        if [ -d "{{ flash_target_dir }}" ]; then
            printf "\nFound it! Flashing...\n"
            cp ./build/{{ nametag }}.uf2 {{ flash_target_dir }}
            echo ✅ Flash Success!
            exit 0
        else
            printf "."
        fi
        sleep 1
    done
    printf "\nDirectory '{{ flash_target_dir }}' did not appear within 30 seconds.\n"
    exit 1

_fix-broken-grammar-parsing:

# build firmware and move it to ./build
build: build_prepare
    podman build \
        --file Containerfile \
        --tag {{ nametag }} \
        --build-arg zmk_shield
    podman run --name {{ nametag }} --replace --detach -t {{ nametag }}
    podman cp {{ nametag }}:/app/zmk.uf2 ./build/{{ nametag }}.uf2
    podman stop {{ nametag }}
    @echo ✅ Build Success!

# build _prepare only if it doesn't exist
[private]
build_prepare:
    if podman image exists {{ nametag }}_prepare; then exit 0; fi
    just rebuild_prepare

# rebuild the _prepare image (in case the ./config/build contents changed)
rebuild_prepare:
    podman build \
        --file Containerfile.prepare \
        --build-arg zmk_board \
        --build-arg zmk_shield \
        --tag {{ nametag }}_prepare

# rebuild the _prepare image fully (for new zmk version etc.)
rebuild_prepare_no_cache: && build
    podman build --no-cache \
        --file Containerfile.prepare \
        --build-arg zmk_board \
        --build-arg zmk_shield \
        --tag {{ nametag }}_prepare

#
# Keymap Drawer
#

export PATH := "../.venv/bin:" + env('PATH')
keymap := "config" / keyboard + ".keymap"
kmd := "./keymap_drawer"
kmd_parsed := kmd / keyboard + ".yaml"
kmd_config := kmd / "config.yaml"
kmd_svg := kmd / keyboard + ".svg"

[group('Keymap Drawer')]
watch_draw:
    watchexec \
        --watch ./config \
        --watch {{ kmd_config }} \
        'just draw'

[group('Keymap Drawer')]
draw: parse
    keymap --config {{ kmd_config }} \
        draw \
        {{ kmd_parsed }} \
        > {{ kmd_svg }}

_fix-broken-grammar-parsing-2:

[group('Keymap Drawer')]
parse:
    keymap --config {{ kmd_config }} \
        parse \
        --base-keymap {{ kmd_parsed }} \
        --zmk-keymap {{ keymap }} \
        > {{ kmd_parsed }}.new
    mv {{ kmd_parsed }}.new {{ kmd_parsed }}
