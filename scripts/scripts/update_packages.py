# scripts/update_packages.py
import requests
from bs4 import BeautifulSoup
import json
from datetime import datetime
from pathlib import Path

class PubDevScraper:
    """Scraper för att hämta packages från pub.dev"""
    
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        })
    
    def get_packages_from_publisher(self, publisher):
        """Hämta alla packages från en publisher"""
        url = f"https://pub.dev/publishers/{publisher}/packages"
        print(f"🔍 Checking publisher: {url}")
        
        try:
            response = self.session.get(url, timeout=10)
            if response.status_code == 200:
                packages = self._extract_packages_from_html(response.text)
                if packages:
                    print(f"✓ Found {len(packages)} packages from publisher")
                    return packages
        except Exception as e:
            print(f"⚠️  Publisher check failed: {e}")
        
        return []
    
    def get_packages_from_search(self, query):
        """Sök efter packages via pub.dev search"""
        url = f"https://pub.dev/packages?q={query}"
        print(f"🔍 Searching: {url}")
        
        try:
            response = self.session.get(url, timeout=10)
            if response.status_code == 200:
                packages = self._extract_packages_from_html(response.text)
                if packages:
                    print(f"✓ Found {len(packages)} packages from search")
                    return packages
        except Exception as e:
            print(f"⚠️  Search failed: {e}")
        
        return []
    
    def _extract_packages_from_html(self, html_content):
        """Extrahera package-namn från HTML"""
        soup = BeautifulSoup(html_content, 'html.parser')
        packages = set()
        
        # Olika selectors för olika page layouts
        selectors = [
            ('a', {'href': lambda x: x and x.startswith('/packages/')}),
            ('h3.packages-title a', {}),
            ('.package-name a', {}),
        ]
        
        for tag, attrs in selectors:
            links = soup.find_all(tag, attrs) if attrs else soup.select(tag)
            for link in links:
                href = link.get('href', '')
                if '/packages/' in href:
                    # Extrahera bara package-namnet
                    parts = href.split('/packages/')
                    if len(parts) > 1:
                        package_name = parts[1].split('/')[0].split('?')[0]
                        if package_name and '/' not in package_name:
                            packages.add(package_name)
        
        return list(packages)
    
    def get_package_info(self, package_name):
        """Hämta detaljerad info om ett package"""
        url = f"https://pub.dev/api/packages/{package_name}"
        
        try:
            response = self.session.get(url, timeout=10)
            if response.status_code == 200:
                data = response.json()
                return {
                    'package': package_name,
                    'version': data['latest']['version'],
                    'description': data['latest'].get('pubspec', {}).get('description', ''),
                    'published': data['latest'].get('published', ''),
                }
        except Exception as e:
            print(f"⚠️  Error fetching {package_name}: {e}")
        
        return None


class ReadmeGenerator:
    """Generera README.md från package data"""
    
    @staticmethod
    def generate(packages, fallback_used=False):
        """Skapa README innehåll"""
        lines = [
            "# 📦 GLLB-Apps Dart Packages\n",
            "My published packages on pub.dev\n",
        ]
        
        if fallback_used:
            lines.append("*Note: Using fallback package list (scraping unavailable)*\n")
        
        if not packages:
            lines.append("*No packages found.*\n")
        else:
            # Sortera alfabetiskt
            packages.sort(key=lambda x: x['package'])
            
            lines.extend([
                "| Package | Version | Pub Points | Popularity | Link |",
                "|---------|---------|------------|------------|------|",
            ])
            
            for pkg in packages:
                name = pkg['package']
                lines.append(
                    f"| **{name}** | "
                    f"![version](https://img.shields.io/pub/v/{name}.svg?color=blue) | "
                    f"![points](https://img.shields.io/pub/points/{name}?color=green) | "
                    f"![popularity](https://img.shields.io/pub/popularity/{name}?color=orange) | "
                    f"[pub.dev](https://pub.dev/packages/{name}) |"
                )
        
        lines.extend([
            "\n---",
            f"*Last updated: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')} UTC*",
            "\n*Auto-updated daily via GitHub Actions*",
        ])
        
        return "\n".join(lines)


def main():
    """Main script execution"""
    print("=" * 60)
    print("📦 GLLB-Apps Package Updater")
    print("=" * 60)
    
    scraper = PubDevScraper()
    
    # Försök olika metoder att hitta packages
    all_package_names = []
    
    # Metod 1: Publisher
    packages = scraper.get_packages_from_publisher('gllb-apps.github.io')
    if packages:
        all_package_names.extend(packages)
    
    # Metod 2: Search (om publisher inte fungerade)
    if not all_package_names:
        packages = scraper.get_packages_from_search('publisher:gllb-apps.github.io')
        if packages:
            all_package_names.extend(packages)
    
    # Fallback: Hårdkodad lista
    fallback_used = False
    if not all_package_names:
        print("\n⚠️  Scraping failed, using fallback list...")
        all_package_names = [
            'flux_wireframe_theme_cli',
            'wireframe_theme',
        ]
        fallback_used = True
    
    # Ta bort dubbletter
    all_package_names = list(set(all_package_names))
    print(f"\n📦 Processing {len(all_package_names)} packages...")
    
    # Hämta detaljerad info
    package_infos = []
    for name in all_package_names:
        info = scraper.get_package_info(name)
        if info:
            package_infos.append(info)
            print(f"  ✓ {name} v{info['version']}")
        else:
            print(f"  ✗ {name} (failed)")
    
    # Generera README
    print(f"\n📝 Generating README...")
    readme_content = ReadmeGenerator.generate(package_infos, fallback_used)
    
    # Skriv till fil
    readme_path = Path(__file__).parent.parent / 'README.md'
    readme_path.write_text(readme_content, encoding='utf-8')
    
    print(f"✅ Updated {len(package_infos)} packages!")
    print(f"📄 Wrote to: {readme_path}")
    print("=" * 60)


if __name__ == "__main__":
    main()