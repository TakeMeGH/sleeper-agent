# Epic: Last Dose

> **Status**: Not started
> **Source**: `design/game-brief.md` (no GDDs or ADRs at `minimal`)
> **Engine**: Godot 4.7 · GDScript · Forward+ · Jolt (3D)
> **Created**: 2026-11-25

## Goal

A first-person shooter against waves of armed humans where your heart is the clock: coffee raises your heart rate, cigarettes lower it, each zone gives an edge (slow motion when calm, superspeed when racing), and the run lasts until you pass out or have a heart attack.

## Scope

The brief's MVP list, in its Build order. Out of scope is the brief's own list: multiplayer, more than 2 substances, more than 2 levels / 3 enemy types / 3 guns, upgrades and save files, crafting, story and a full settings menu.

Stories 011–023 cover the port-parity items (brief MVP features 12–24), added 2026-11-25 from the Unity version's later stories. The brief's *Art & audio direction* is covered by stories 012–014.

This is a Godot port of a game already built in Unity. The Unity version is a reference for behaviour, not code to translate.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Weapons pass: first-person view, pistol, SMG, shotgun | Logic | Complete | N/A |
| 002 | Heart rate, five zones, passing out and heart attack | Logic | Complete | N/A |
| 003 | Coffee and cigarette, held to consume | Logic | Complete | N/A |
| 004 | Two-handed viewmodel and consuming in first person | Visual/Feel | Ready | N/A |
| 005 | Status-bar HUD | UI | Complete | N/A |
| 006 | Shift: slow motion and superspeed | Logic | Complete | N/A |
| 007 | Dive | Visual/Feel | In Progress | N/A |
| 008 | Human enemies and the wave mix | Logic | Complete | N/A |
| 009 | Canteen and plaza levels, waves, exit and rotation | Integration | Complete | N/A |
| 010 | Run-end screen and restart | UI | Complete | N/A |
| 011 | Shooting feel: recoil, flash, impacts, blood, hit feedback, arms | Visual/Feel | Ready | N/A |
| 012 | Audio: guns, impacts, substances, heart rate, footsteps, music | Visual/Feel | Ready | N/A |
| 013 | Ability screen feel: slow-motion and superspeed look | Visual/Feel | Ready | N/A |
| 014 | Heart-rate vignette and field of view | Visual/Feel | In Progress | N/A |
| 015 | Hit direction arcs and danger countdown on the crosshair | UI | Complete | N/A |
| 016 | Slow-motion player edge | Integration | Complete | N/A |
| 017 | The dive clears obstacles | Visual/Feel | Ready | N/A |
| 018 | Death and loading flow: collapse, fades, tip | Visual/Feel | In Progress | N/A |
| 019 | Enemy variety: group spawns and ranged gun variants | Logic | Complete | N/A |
| 020 | Human enemy models and animations | Visual/Feel | Ready | N/A |
| 021 | Enemies push tables aside | Integration | Complete | N/A |
| 022 | Canteen and plaza art, asset port and shaders | Visual/Feel | Ready | N/A |
| 023 | Tutorial in the gameplay | Integration | Complete | N/A |
