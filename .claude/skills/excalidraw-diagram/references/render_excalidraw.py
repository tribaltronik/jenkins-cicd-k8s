#!/usr/bin/env python3
import json
import sys
from pathlib import Path

try:
    from playwright.sync_api import sync_playwright
except ImportError:
    print("Installing playwright...")
    import subprocess

    subprocess.run([sys.executable, "-m", "pip", "install", "playwright"], check=True)
    subprocess.run(
        [sys.executable, "-m", "playwright", "install", "chromium"], check=True
    )
    from playwright.sync_api import sync_playwright


def render_excalidraw(input_file, output_file=None):
    with open(input_file, "r") as f:
        data = json.load(f)

    if output_file is None:
        output_file = str(Path(input_file).with_suffix(".png"))

    # Generate embeddable HTML
    elements_json = json.dumps(data.get("elements", []))
    app_state_json = json.dumps(data.get("appState", {}))

    html_content = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <script src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
    <script src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
    <script src="https://unpkg.com/@excalidraw/excalidraw@0.17.6/dist/excalidraw.develop.umd.js"></script>
    <link rel="stylesheet" href="https://unpkg.com/@excalidraw/excalidraw@0.17.6/dist/excalidraw.develop.css" />
    <style>
        body {{ margin: 0; padding: 0; overflow: hidden; }}
        #app {{ width: 100vw; height: 100vh; }}
    </style>
</head>
<body>
    <div id="app"></div>
    <script>
        const excalidrawRef = React.createRef();
        const elements = {elements_json};
        const appState = {app_state_json};
        
        const excalidrawProps = {{
            initialData: {{ elements, appState }},
            viewOnlyEnabled: true,
            zenModeEnabled: true,
            canvasBackgroundColor: "#ffffff"
        }};
        
        window.ExcalidrawApp = ReactDOM.render(
            React.createElement(Excalidraw.Excalidraw, excalidrawProps),
            document.getElementById("app")
        );
        
        // Wait for render then capture
        setTimeout(() => {{
            const svg = document.querySelector("svg");
            if (svg) {{
                const canvas = document.createElement("canvas");
                const ctx = canvas.getContext("2d");
                const img = new Image();
                const svgData = new XMLSerializer().serializeToString(svg);
                img.onload = function() {{
                    canvas.width = svg.width.baseVal.value;
                    canvas.height = svg.height.baseVal.value;
                    ctx.drawImage(img, 0, 0);
                    const link = document.createElement("a");
                    link.download = "diagram.png";
                    link.href = canvas.toDataURL("image/png");
                    link.click();
                    window.close();
                }};
                img.src = "data:image/svg+xml;base64," + btoa(unescape(encodeURIComponent(svgData)));
            }}
        }}, 2000);
    </script>
</body>
</html>"""

    with open("/tmp/excalidraw_render.html", "w") as f:
        f.write(html_content)

    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page()
        page.goto(f"file:///tmp/excalidraw_render.html")
        page.wait_for_timeout(3000)
        page.screenshot(path=output_file, full_page=True)
        browser.close()

    print(f"Diagram saved to: {output_file}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: render.py <input.excalidraw> [output.png]")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    render_excalidraw(input_file, output_file)
