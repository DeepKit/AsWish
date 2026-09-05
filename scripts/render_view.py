"""
HTML to image renderer for AsWish GUI preview compositing.
Uses Microsoft Edge (Chromium) headless rendering to produce exact WebView2 visual representation.
"""
import sys
import os
import subprocess
import shutil

def find_browser_executable() -> str:
    candidates = [
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
        shutil.which("msedge"),
        r"C:\Program Files\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
        shutil.which("chrome"),
    ]
    for c in candidates:
        if c and os.path.isfile(c):
            return c
    return ""

def render_html_to_png(html_path: str, output_png: str, width: int = 900, height: int = 650) -> bool:
    if not os.path.exists(html_path):
        return False

    abs_html = os.path.abspath(html_path)
    abs_out = os.path.abspath(output_png)
    os.makedirs(os.path.dirname(abs_out), exist_ok=True)

    browser = find_browser_executable()
    if browser:
        file_url = f"file:///{abs_html.replace(os.sep, '/')}"
        cmd = [
            browser,
            "--headless=new",
            "--disable-gpu",
            "--no-sandbox",
            f"--screenshot={abs_out}",
            f"--window-size={width},{height}",
            file_url
        ]
        try:
            subprocess.run(cmd, capture_output=True, text=True, timeout=15)
            if os.path.exists(abs_out) and os.path.getsize(abs_out) > 0:
                return True
        except Exception:
            pass

    return False

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: render_view.py <input.html> <output.png> [width] [height]")
        sys.exit(1)
    w = int(sys.argv[3]) if len(sys.argv) > 3 else 900
    h = int(sys.argv[4]) if len(sys.argv) > 4 else 650
    ok = render_html_to_png(sys.argv[1], sys.argv[2], w, h)
    sys.exit(0 if ok else 1)
