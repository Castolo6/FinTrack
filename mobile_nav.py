import os
import re

pages_dir = 'src/pages'
for root, _, files in os.walk(pages_dir):
    for file in files:
        if file.endswith('.astro'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r') as f:
                content = f.read()
            
            if 'import Sidebar' in content and 'MobileTabBar' not in content:
                # Add import
                content = content.replace("import Sidebar from '../components/Sidebar.astro';", "import Sidebar from '../components/Sidebar.astro';\nimport MobileTabBar from '../components/MobileTabBar.astro';")
                content = content.replace("import Sidebar from '../../components/Sidebar.astro';", "import Sidebar from '../../components/Sidebar.astro';\nimport MobileTabBar from '../../components/MobileTabBar.astro';")
                
                def replacer(match):
                    full_sidebar = match.group(0)
                    active_prop = match.group(1)
                    return f'<div class="hidden md:flex flex-shrink-0">\n      {full_sidebar}\n    </div>\n    <MobileTabBar active="{active_prop}" />'
                
                # Regex to find <Sidebar active="something" ... />
                content = re.sub(r'<Sidebar\s+active="([^"]+)"[^>]*/>', replacer, content)
                
                # Add bottom padding to main so the MobileTabBar doesn't cover content
                # Look for <main class="..."> and add pb-24 md:pb-6
                # Just replace "p-6" with "p-6 pb-24 md:pb-6"
                content = content.replace('p-6 space-y-6', 'p-6 pb-24 md:pb-6 space-y-6')
                
                with open(filepath, 'w') as f:
                    f.write(content)
                print(f"Updated {filepath}")
