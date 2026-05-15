# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository status

This repository contains the design for a home background music player (target hardware: RK3308 + AP6256, Rockchip 原厂 SDK / Buildroot-style). **No source code is committed yet.** The current artifact is the integration plan in `docs/matter-integration.md`.

If asked how to build, run, or test, state plainly that no source exists yet. Do not invent commands or file layouts beyond what the design document specifies — and even then, mark them as planned, not present.

## Project direction (per `docs/matter-integration.md`)

- Hardware: RK3308 / AP6256 BT-only / Ethernet-only (no Wi-Fi)
- BT stack: Broadcom BSA (not BlueZ), serving the in-house App's BLE GATT. Must remain untouched.
- Audio streaming: shairport-sync (AirPlay 2) already in production, uses system Avahi.
- Goal: integrate Matter so the device joins Apple Home / Google Home / Alexa / 米家 as a Speaker (Device Type `0x0022`), without disturbing existing BSA / shairport-sync.
- Strategy: **Matter over Ethernet with On-Network Commissioning, BLE disabled in Matter.** Justified because BLE in Matter exists to ferry Wi-Fi/Thread credentials — irrelevant when the device is wired.

When real code lands, replace this file with concrete build / run / test commands and a high-level architecture pointer.

## Branch convention

Development for the current Claude-assisted task happens on `claude/audio-player-matter-integration-8NOI6`. Push to that branch; do not push to `master`/`main` without explicit instruction.
