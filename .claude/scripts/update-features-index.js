const fs = require('fs');
const path = require('path');

const featuresDir = path.join(__dirname, '../../docs/features');
const projectContextPath = path.join(__dirname, '../../PROJECT_CONTEXT.md');

const files = fs.readdirSync(featuresDir).filter(f => f.endsWith('.md'));

const features = files.map(file => {
    const content = fs.readFileSync(path.join(featuresDir, file), 'utf-8');
    const frontmatter = content.match(/^---\n([\s\S]*?)\n---/)?.[1] || '';
    const get = (key) => frontmatter.match(new RegExp(`${key}:\\s*(.+)`))?.[1]?.trim() || '?';
    return {
        slug: file.replace('.md', ''),
        status: get('status'),
        scope: get('scope'),
    };
});

const table = [
    '## Index des features (auto-généré, ne pas éditer à la main)',
    '',
    '| Feature | Scope | Statut | Doc |',
    '|---|---|---|---|',
    ...features.map(f => `| ${f.slug} | ${f.scope} | ${f.status} | docs/features/${f.slug}.md |`),
].join('\n');

let content = fs.readFileSync(projectContextPath, 'utf-8');
const marker = /## Index des features[\s\S]*?(?=\n## |\n?$)/;
content = marker.test(content) ? content.replace(marker, table) : content + '\n\n' + table;

fs.writeFileSync(projectContextPath, content);