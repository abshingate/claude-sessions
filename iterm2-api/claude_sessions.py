#!/usr/bin/env python3
"""
claude_sessions.py — iTerm2 Python API daemon for the claude-sessions tools.

Runs automatically when iTerm2 starts (it lives in Scripts/AutoLaunch).

What it does today
------------------
* **Window title** — shows the focused session's REAL working directory, which
  is the thing iTerm2 cannot see for itself: inside tmux its PWD component
  reports the outer shell's cwd, not the pane's. tmux knows; we ask it.
* **Tab titles** — keeps each tab named after its tmux session, so tabs stay
  short and scannable while the wide window bar carries the detail.

Why the API and not AppleScript
-------------------------------
Three AppleScript/tmux routes were tried and all failed: `tmux set-titles`
fixes the window bar but widens every tab (it drives both); an OSC 2 escape
is blocked by `set-titles off`, which is required to keep tabs short; and a
custom window title reading a user variable rendered empty. The API can set a
window title independently of the tab, which is exactly the missing piece.

Adding features
---------------
Each feature is a small async function taking the connection. Register it in
main(). The monitors are the useful hooks:
  * iterm2.FocusMonitor      - the focused session changed
  * iterm2.NewSessionMonitor - a session was created
  * iterm2.KeystrokeMonitor  - key bindings
"""

import asyncio
import os
import subprocess

import iterm2

HOME = os.path.expanduser("~")


def _sh(cmd):
    """Run a command, return stripped stdout, never raise."""
    try:
        return subprocess.run(cmd, capture_output=True, text=True,
                              timeout=5).stdout.strip()
    except Exception:
        return ""


def tmux_map():
    """{client_tty: session_name} for every attached tmux client."""
    out = _sh(["tmux", "list-clients", "-F", "#{client_tty} #{client_session}"])
    m = {}
    for line in out.splitlines():
        parts = line.split(None, 1)
        if len(parts) == 2:
            m[parts[0]] = parts[1]
    return m


def tmux_path(session):
    """The pane's real cwd - what iTerm2 cannot determine through tmux."""
    p = _sh(["tmux", "display", "-p", "-t", session, "#{pane_current_path}"])
    return p.replace(HOME, "~", 1) if p.startswith(HOME) else p


def session_count():
    out = _sh(["tmux", "ls"])
    return len([l for l in out.splitlines() if l]) if out else 0


async def describe(session):
    """A one-line description of a session: name, directory, total count."""
    if session is None:
        return None
    try:
        tty = await session.async_get_variable("tty")
    except Exception:
        return None
    name = tmux_map().get(tty)
    if not name:
        return None
    path = tmux_path(name)
    n = session_count()
    return f"{name}  —  {path}  ·  {n} sessions"


async def update_window_title(connection, window):
    """Set the window bar from whichever session is focused in it."""
    if window is None:
        return
    try:
        tab = window.current_tab
        if tab is None:
            return
        text = await describe(tab.current_session)
        if text:
            await window.async_set_title(text)
    except Exception:
        pass


async def label_tabs(connection, app):
    """Keep every tab named after its tmux session (short, scannable)."""
    m = tmux_map()
    if not m:
        return
    for window in app.terminal_windows:
        for tab in window.tabs:
            s = tab.current_session
            if s is None:
                continue
            try:
                tty = await s.async_get_variable("tty")
                name = m.get(tty)
                if name:
                    cur = await s.async_get_variable("twoLineName") or ""
                    if cur != name:
                        await s.async_set_name(name)
            except Exception:
                continue


async def main(connection):
    app = await iterm2.async_get_app(connection)

    # Initial pass so things are right immediately, not only after a switch.
    await label_tabs(connection, app)
    await update_window_title(connection, app.current_terminal_window)

    async def on_focus():
        async with iterm2.FocusMonitor(connection) as mon:
            while True:
                await mon.async_get_next_update()
                await update_window_title(
                    connection, app.current_terminal_window)

    async def on_new_session():
        async with iterm2.NewSessionMonitor(connection) as mon:
            while True:
                await mon.async_get()
                await asyncio.sleep(1.0)   # let tmux attach first
                await label_tabs(connection, app)
                await update_window_title(
                    connection, app.current_terminal_window)

    async def periodic():
        """Catch changes no monitor reports - cd'ing inside a pane, a session
        ending elsewhere. Cheap: two tmux calls every few seconds."""
        while True:
            await asyncio.sleep(5)
            await update_window_title(
                connection, app.current_terminal_window)

    await asyncio.gather(on_focus(), on_new_session(), periodic())


iterm2.run_forever(main)
