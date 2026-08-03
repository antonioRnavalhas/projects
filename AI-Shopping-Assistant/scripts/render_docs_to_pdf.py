"""Create print-ready HTML files from the three delivery documents."""

from __future__ import annotations

import html
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
OUTPUT = DOCS / ".pdf-build"
SOURCES = ("AI_USAGE.md", "ARCHITECTURE.md", "DECISION_LOG.md")
FENCE = chr(96) * 3


def inline(text: str) -> str:
    escaped = html.escape(text)
    escaped = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', escaped)
    escaped = re.sub(r"\x60([^\x60]+)\x60", r"<code>\1</code>", escaped)
    escaped = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", escaped)
    return escaped


def cells(line: str) -> list[str]:
    return [inline(part.strip()) for part in line.strip().strip("|").split("|")]


def is_table_separator(line: str) -> bool:
    values = [
        part.strip().replace(":", "").replace("-", "")
        for part in line.strip().strip("|").split("|")
    ]
    return bool(values) and all(not value for value in values)


def mermaid_to_html(source: str) -> str:
    """Create a compact static flow view without a network dependency."""
    nodes: list[str] = []
    pattern = re.compile(r"([A-Za-z0-9_]+)\s*(?:\[\(?([^\]]+)\]|\{([^}]+)\})")
    for match in pattern.finditer(source):
        label = (match.group(2) or match.group(3) or "").strip("() ")
        if label and label not in nodes:
            nodes.append(label)
    cards: list[str] = []
    for position, label in enumerate(nodes):
        if position:
            cards.append('<span class="arrow">→</span>')
        cards.append(f'<span class="node">{inline(label)}</span>')
    return '<div class="diagram">' + "".join(cards) + "</div>"


def markdown_to_html(markdown: str) -> str:
    lines = markdown.splitlines()
    output: list[str] = []
    index = 0
    in_list: str | None = None

    def close_list() -> None:
        nonlocal in_list
        if in_list:
            output.append(f"</{in_list}>")
            in_list = None

    while index < len(lines):
        line = lines[index]
        stripped = line.strip()

        if stripped.startswith(FENCE):
            close_list()
            language = stripped[len(FENCE):].strip()
            index += 1
            body: list[str] = []
            while index < len(lines) and not lines[index].strip().startswith(FENCE):
                body.append(lines[index])
                index += 1
            if language == "mermaid":
                output.append(mermaid_to_html("\n".join(body)))
            else:
                code = html.escape("\n".join(body))
                output.append(f'<pre class="code"><code>{code}</code></pre>')
            index += 1
            continue

        if "|" in stripped and index + 1 < len(lines) and is_table_separator(lines[index + 1]):
            close_list()
            headers = cells(line)
            index += 2
            rows: list[list[str]] = []
            while index < len(lines) and "|" in lines[index]:
                rows.append(cells(lines[index]))
                index += 1
            output.append("<table><thead><tr>" + "".join(f"<th>{cell}</th>" for cell in headers) + "</tr></thead><tbody>")
            for row in rows:
                output.append("<tr>" + "".join(f"<td>{cell}</td>" for cell in row) + "</tr>")
            output.append("</tbody></table>")
            continue

        heading = re.match(r"^(#{1,3})\s+(.+)$", stripped)
        if heading:
            close_list()
            level = len(heading.group(1))
            output.append(f"<h{level}>{inline(heading.group(2))}</h{level}>")
        elif stripped in {"---", "***"}:
            close_list()
            output.append("<hr>")
        elif re.match(r"^[-*]\s+", stripped):
            if in_list != "ul":
                close_list()
                output.append("<ul>")
                in_list = "ul"
            output.append(f"<li>{inline(re.sub(r'^[-*]\s+', '', stripped))}</li>")
        elif re.match(r"^\d+\.\s+", stripped):
            if in_list != "ol":
                close_list()
                output.append("<ol>")
                in_list = "ol"
            output.append(f"<li>{inline(re.sub(r'^\d+\.\s+', '', stripped))}</li>")
        elif stripped.startswith(">"):
            close_list()
            output.append(f"<blockquote>{inline(stripped[1:].strip())}</blockquote>")
        elif stripped:
            close_list()
            output.append(f"<p>{inline(stripped)}</p>")
        else:
            close_list()
        index += 1

    close_list()
    return "\n".join(output)


def document_html(title: str, body: str) -> str:
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>{html.escape(title)}</title>
<style>
@page {{ size: A4; margin: 18mm 16mm 18mm; }}
body {{ color:#1c2733; font:10.5pt/1.48 Arial, Helvetica, sans-serif; }}
h1 {{ color:#111b29; font-size:25pt; margin:0 0 18pt; padding-bottom:8pt; border-bottom:2px solid #d47b4d; }}
h2 {{ color:#263849; font-size:16pt; margin:24pt 0 9pt; }}
h3 {{ color:#263849; font-size:12pt; margin:18pt 0 6pt; }}
p {{ margin:0 0 9pt; }} ul, ol {{ margin:0 0 10pt; padding-left:22pt; }}
li {{ margin:3pt 0; }} code {{ background:#f1f3f5; border-radius:3px; padding:1px 3px; font-family:Consolas, monospace; font-size:9pt; }}
pre.code {{ background:#15212e; color:#ecf2f7; padding:10pt; white-space:pre-wrap; border-radius:5px; font-size:8.5pt; line-height:1.35; }}
.diagram {{ display:flex; flex-wrap:wrap; gap:6pt; align-items:center; padding:10pt; background:#f7f8fa; border:1px solid #d9dfe5; border-radius:5px; }}
.node {{ display:inline-block; padding:5pt 7pt; background:#fff; border:1px solid #73879a; border-radius:4pt; font-size:8.5pt; }}
.arrow {{ color:#95502d; font-size:14pt; font-weight:bold; }}
table {{ border-collapse:collapse; width:100%; margin:10pt 0 14pt; font-size:9pt; }}
th {{ background:#263849; color:white; text-align:left; }} th, td {{ border:1px solid #cbd3db; padding:5pt; vertical-align:top; }}
tr:nth-child(even) {{ background:#f6f8fa; }} blockquote {{ margin:10pt 0; padding:7pt 11pt; border-left:3px solid #d47b4d; background:#fbf7f4; }}
a {{ color:#95502d; }} hr {{ border:0; border-top:1px solid #d9dfe5; margin:18pt 0; }}
</style>
</head>
<body>{body}</body>
</html>"""


def main() -> None:
    OUTPUT.mkdir(exist_ok=True)
    for source_name in SOURCES:
        source = DOCS / source_name
        target = OUTPUT / f"{source.stem}.html"
        target.write_text(
            document_html(
                source.stem.replace("_", " "),
                markdown_to_html(source.read_text(encoding="utf-8")),
            ),
            encoding="utf-8",
        )
        print(target)


if __name__ == "__main__":
    main()
