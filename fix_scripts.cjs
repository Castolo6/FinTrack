const fs = require('fs');
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
  
  if (content.includes('astro:page-load')) return;

  let modified = false;
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
