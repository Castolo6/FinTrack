const fs = require('fs');
const glob = require('glob'); // npm install glob if needed, but I can just use fs.readdirSync
const path = require('path');

const walkSync = (dir, filelist = []) => {
  fs.readdirSync(dir).forEach(file => {
    const dirFile = path.join(dir, file);
    if (fs.statSync(dirFile).isDirectory()) {
      filelist = walkSync(dirFile, filelist);
    } else if (dirFile.endsWith('.astro')) {
      filelist.push(dirFile);
    }
  });
  return filelist;
};

const files = walkSync('./src');

files.forEach(file => {
  let content = fs.readFileSync(file, 'utf8');
  
  // Skip if it already has astro:page-load
  if (content.includes('astro:page-load')) return;

  // We only want to wrap standard <script> tags, not <script is:inline> or <script define:vars
  // Wait, actually <script> is fine to wrap.
  
  let modified = false;
  // Replace <script> ... </script>
  // Regex to match <script> exactly (no attributes)
  content = content.replace(/<script>\s*([\s\S]*?)\s*<\/script>/g, (match, inner) => {
    modified = true;
    return `<script>
  document.addEventListener('astro:page-load', () => {
${inner}
  });
</script>`;
  });

  if (modified) {
    fs.writeFileSync(file, content);
    console.log('Fixed:', file);
  }
});
