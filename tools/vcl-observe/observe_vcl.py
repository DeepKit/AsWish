#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
observe_vcl.py - Non-invasive VCL Reality Observer (WO-0108 Stage 2.5 / WP2)

Launches target VCL executable, captures child control bounds relative to
the form client area using standard Windows Win32 / UIA APIs without requiring
target application code instrumentation, and outputs observations in JSON.
Unobservable styles (such as FontColor) are explicitly output as null.
"""

import sys
import os
import re
import time
import json
import argparse
import subprocess
import ctypes
from ctypes import wintypes

# Win32 definitions
user32 = ctypes.windll.user32
kernel32 = ctypes.windll.kernel32

WNDENUMPROC = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)

class POINT(ctypes.Structure):
    _fields_ = [("x", wintypes.LONG), ("y", wintypes.LONG)]

WM_CLOSE = 0x0010
GW_OWNER = 4
WS_VISIBLE = 0x10000000

def parse_dfm_file(dfm_path):
    """
    Parse a Delphi text DFM file to extract object declarations:
    Name, ClassName, Caption, Left, Top, Width, Height.
    Returns a dict: name -> info, and caption -> info
    """
    controls = {}
    captions = {}
    if not os.path.isfile(dfm_path):
        return controls, captions

    try:
        with open(dfm_path, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
    except Exception:
        return controls, captions

    # Match object blocks: object Name: ClassName ... end
    obj_pattern = re.compile(
        r'object\s+([A-Za-z0-9_]+)\s*:\s*([A-Za-z0-9_]+)(.*?)(?=\bobject\b|\bend\b)',
        re.DOTALL | re.IGNORECASE
    )
    for match in obj_pattern.finditer(content):
        name = match.group(1).strip()
        cls_name = match.group(2).strip()
        body = match.group(3)

        caption_match = re.search(r"Caption\s*=\s*'([^']*)'", body, re.IGNORECASE)
        caption = caption_match.group(1) if caption_match else ""

        left_match = re.search(r"Left\s*=\s*([0-9]+)", body, re.IGNORECASE)
        top_match = re.search(r"Top\s*=\s*([0-9]+)", body, re.IGNORECASE)
        width_match = re.search(r"Width\s*=\s*([0-9]+)", body, re.IGNORECASE)
        height_match = re.search(r"Height\s*=\s*([0-9]+)", body, re.IGNORECASE)

        info = {
            "name": name,
            "class": cls_name,
            "caption": caption,
            "left": int(left_match.group(1)) if left_match else None,
            "top": int(top_match.group(1)) if top_match else None,
            "width": int(width_match.group(1)) if width_match else None,
            "height": int(height_match.group(1)) if height_match else None,
        }
        controls[name.lower()] = info
        if caption:
            captions[caption.lower()] = info

    return controls, captions

def discover_dfm_mappings(start_dir):
    """Scan directory and parents for .dfm files."""
    controls = {}
    captions = {}
    curr = os.path.abspath(start_dir)
    for _ in range(4):  # Check up to 4 levels up
        for root, _, files in os.walk(curr):
            for f in files:
                if f.lower().endswith(".dfm"):
                    dfm_path = os.path.join(root, f)
                    c_map, cap_map = parse_dfm_file(dfm_path)
                    controls.update(c_map)
                    captions.update(cap_map)
        parent = os.path.dirname(curr)
        if parent == curr:
            break
        curr = parent
    return controls, captions

def get_hwnds_for_pid(pid):
    hwnds = []
    def enum_cb(hwnd, lparam):
        wpid = wintypes.DWORD()
        user32.GetWindowThreadProcessId(hwnd, ctypes.byref(wpid))
        if wpid.value == pid:
            hwnds.append(hwnd)
        return True
    user32.EnumWindows(WNDENUMPROC(enum_cb), 0)
    return hwnds

def find_main_form_hwnd(pid, timeout=5.0):
    start = time.time()
    while time.time() - start < timeout:
        for hwnd in get_hwnds_for_pid(pid):
            if user32.IsWindowVisible(hwnd):
                # Check that it's a top-level window (no owner or owner is 0)
                owner = user32.GetWindow(hwnd, GW_OWNER)
                if owner == 0:
                    length = user32.GetWindowTextLengthW(hwnd)
                    buf = ctypes.create_unicode_buffer(length + 1)
                    user32.GetWindowTextW(hwnd, buf, length + 1)
                    # VCL forms usually have a title or standard size
                    rect = wintypes.RECT()
                    user32.GetWindowRect(hwnd, ctypes.byref(rect))
                    width = rect.right - rect.left
                    height = rect.bottom - rect.top
                    if width > 100 and height > 80:
                        return hwnd
        time.sleep(0.1)
    return None

def observe_process(exe_path, timeout=5.0, wait_seconds=0.5, dfm_dir=None):
    if not os.path.isfile(exe_path):
        raise FileNotFoundError(f"Target executable not found: {exe_path}")

    search_dir = dfm_dir or os.path.dirname(exe_path)
    dfm_controls, dfm_captions = discover_dfm_mappings(search_dir)

    # Launch process non-invasively
    proc = subprocess.Popen([exe_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        main_hwnd = find_main_form_hwnd(proc.pid, timeout=timeout)
        if not main_hwnd:
            raise RuntimeError(f"Could not find visible main form window for PID {proc.pid} within {timeout}s")

        if wait_seconds > 0:
            time.sleep(wait_seconds)

        # Obtain client origin in screen coordinates
        pt = POINT(0, 0)
        user32.ClientToScreen(main_hwnd, ctypes.byref(pt))
        client_origin_x = pt.x
        client_origin_y = pt.y

        child_hwnds = []
        def enum_child_cb(hwnd, lparam):
            if user32.IsWindowVisible(hwnd):
                child_hwnds.append(hwnd)
            return True
        user32.EnumChildWindows(main_hwnd, WNDENUMPROC(enum_child_cb), 0)

        observations = []
        for chwnd in child_hwnds:
            rect = wintypes.RECT()
            user32.GetWindowRect(chwnd, ctypes.byref(rect))

            left = rect.left - client_origin_x
            top = rect.top - client_origin_y
            width = rect.right - rect.left
            height = rect.bottom - rect.top

            # Get Class Name
            cls_buf = ctypes.create_unicode_buffer(256)
            user32.GetClassNameW(chwnd, cls_buf, 256)
            raw_class = cls_buf.value

            # Get Window Text / Caption
            txt_len = user32.GetWindowTextLengthW(chwnd)
            txt_buf = ctypes.create_unicode_buffer(txt_len + 1)
            user32.GetWindowTextW(chwnd, txt_buf, txt_len + 1)
            raw_text = txt_buf.value

            # Resolve name and component class using DFM or window heuristics
            ctrl_name = ""
            canonical_class = "TWinControl"

            if raw_class.lower() in ("button", "tbutton"):
                canonical_class = "TButton"
            elif raw_class.lower() in ("edit", "tedit"):
                canonical_class = "TEdit"
            elif "panel" in raw_class.lower():
                canonical_class = "TPanel"
            else:
                canonical_class = raw_class

            # 1. Match by caption in DFM
            if raw_text.lower() in dfm_captions:
                matched = dfm_captions[raw_text.lower()]
                ctrl_name = matched["name"]
                if matched["class"]:
                    canonical_class = matched["class"]
            # 2. Match by text directly if DFM has matching name
            elif raw_text.lower() in dfm_controls:
                matched = dfm_controls[raw_text.lower()]
                ctrl_name = matched["name"]
                if matched["class"]:
                    canonical_class = matched["class"]
            else:
                # Fallback: if raw_text is valid identifier-like string
                clean_text = re.sub(r'[^A-Za-z0-9_]', '', raw_text)
                if clean_text:
                    if canonical_class == "TButton" and not clean_text.lower().startswith("btn"):
                        ctrl_name = f"Btn{clean_text}"
                    else:
                        ctrl_name = clean_text
                else:
                    ctrl_name = f"{canonical_class}_{len(observations) + 1}"

            obs_item = {
                "Name": ctrl_name,
                "ClassName": canonical_class,
                "Bounds": {
                    "Left": int(left),
                    "Top": int(top),
                    "Width": int(width),
                    "Height": int(height)
                },
                "FontColor": None  # Unobservable style explicitly output as null
            }
            observations.append(obs_item)

        return {"Observations": observations}

    finally:
        # Gracefully close window and ensure process terminates
        if proc.poll() is None:
            user32.PostMessageW(main_hwnd, WM_CLOSE, 0, 0)
            try:
                proc.wait(timeout=1.0)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait(timeout=1.0)

def main():
    parser = argparse.ArgumentParser(description="AsWish Non-Invasive VCL Reality Observer")
    parser.add_argument("--exe", required=True, help="Path to target VCL executable")
    parser.add_argument("--output", required=True, help="Path to output observation JSON file")
    parser.add_argument("--timeout", type=float, default=5.0, help="Window discovery timeout in seconds (default: 5.0)")
    parser.add_argument("--wait-seconds", type=float, default=0.5, help="Post-show stabilization wait (default: 0.5)")
    parser.add_argument("--dfm-dir", default=None, help="Optional directory to search for DFM files")

    args = parser.parse_args()

    try:
        data = observe_process(
            exe_path=os.path.abspath(args.exe),
            timeout=args.timeout,
            wait_seconds=args.wait_seconds,
            dfm_dir=args.dfm_dir
        )
    except Exception as e:
        sys.stderr.write(f"[observe_vcl] ERROR: {e}\n")
        sys.exit(1)

    out_dir = os.path.dirname(os.path.abspath(args.output))
    if out_dir and not os.path.exists(out_dir):
        os.makedirs(out_dir, exist_ok=True)

    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    sys.stdout.write(f"[observe_vcl] Successfully recorded {len(data['Observations'])} controls to {args.output}\n")
    sys.exit(0)

if __name__ == "__main__":
    main()
