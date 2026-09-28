"""Check rendered navigation and XML: python scripts/check_sitemap.py BUILD_DIR SITE_URL."""
import re
import sys
import xml.etree.ElementTree as ET
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlparse

root = Path(sys.argv[1])
base = sys.argv[2].rstrip('/')
base_path = urlparse(base).path

class Navigation(HTMLParser):
    def __init__(self):
        super().__init__()
        self.depth = 0
        self.links = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'div':
            if 'sitemap-index' in attrs.get('class', '').split() or self.depth:
                self.depth += 1
        if self.depth and tag == 'a':
            self.links.append(attrs.get('href', ''))

    def handle_endtag(self, tag):
        if tag == 'div' and self.depth:
            self.depth -= 1


def output(url):
    parsed = urlparse(url)
    assert not parsed.netloc or parsed.netloc == urlparse(base).netloc, f'Wrong host: {url}'
    path = urlparse(url).path
    assert path.startswith(base_path + '/') or path == base_path
    path = path[len(base_path):].lstrip('/')
    file = root / path
    if file.is_dir():
        file /= 'index.html'
    if not file.exists() and file.with_suffix('.html').exists():
        file = file.with_suffix('.html')
    assert file.is_file(), f'Missing output: {url}'

namespace = {'s': 'http://www.sitemaps.org/schemas/sitemap/0.9'}
urls = [node.text for node in ET.parse(root / 'sitemap.xml').findall('s:url/s:loc', namespace)]

for locale in ['', '/zh']:
    html = (root / locale.lstrip('/') / 'sitemap/index.html').read_text()
    nav = Navigation()
    nav.feed(html)
    paper_count = sum(url.startswith(base + locale + '/publication/') for url in urls)
    note_count = sum(url.startswith(base + locale + '/posts/') for url in urls)
    assert len(nav.links) == paper_count + note_count + (5 if locale else 6), nav.links
    assert len(nav.links) == len(set(nav.links)), 'Duplicate navigation links'
    assert not re.search(r'&lt;/?(?:article|div|a|h[1-6])\b', html), 'Escaped markup'
    assert not re.search(r'<(?:article|img|details)\b', html), 'Full cards leaked into navigation'
    assert sum('/publication/' in link for link in nav.links) == paper_count
    assert sum('/posts/' in link for link in nav.links) == note_count
    for link in nav.links:
        assert '/404' not in link and '/sitemap/' not in link
        relative = urlparse(link).path[len(base_path):]
        assert relative.startswith('/zh/') == bool(locale), link
        output(link)
    print(f'{locale or "en"}: {len(nav.links)} real, unique, locale-correct navigation links')

assert len(urls) == len(set(urls))
for url in urls:
    assert url.startswith(base + '/')
    assert not any(part in url for part in ['/404', '/archive-layout-with-content', '/portfolio', '/talks', '/experience'])
    output(url)
print(f'XML: {len(urls)} unique canonical URLs, each resolves to an output file')
