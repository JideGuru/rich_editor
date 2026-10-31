// Bundles src/ into assets/editor/editor.js, the script the editor page loads, and collects the
// licenses of the packages in it into assets/editor/editor.js.LICENSE.txt.
// `node build.mjs --check` fails instead when the committed files are out of date.

import * as esbuild from 'esbuild';
import { readdir, readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

const assets = new URL('../../assets/editor/', import.meta.url);
const check = process.argv.includes('--check');

const result = await esbuild.build({
  entryPoints: [fileURLToPath(new URL('src/main.js', import.meta.url))],
  bundle: true,
  format: 'iife',
  minify: true,
  // Android System WebView and iOS WKWebView of the oldest devices Flutter supports
  target: ['chrome80', 'safari14.1'],
  legalComments: 'none', // collected below instead
  banner: { js: '// Generated from tool/editor with `npm run build`; edit the sources there. Licenses: editor.js.LICENSE.txt' },
  metafile: true,
  write: false,
  logLevel: 'warning',
});

const files = {
  'editor.js': result.outputFiles[0].text,
  'editor.js.LICENSE.txt': await licenses(Object.keys(result.metafile.inputs)),
};

// The license of every package with code in the bundle.
async function licenses(inputs) {
  const packages = [...new Set(inputs
    .map((input) => /^node_modules\/((?:@[^/]+\/)?[^/]+)\//.exec(input))
    .filter(Boolean)
    .map((match) => match[1]))].sort();

  const sections = [];
  for (const name of packages) {
    const directory = new URL(`node_modules/${name}/`, import.meta.url);
    const manifest = JSON.parse(await readFile(new URL('package.json', directory), 'utf8'));
    const licenseFile = (await readdir(directory)).find((file) => /^(licen[sc]e|copying)/i.test(file));
    if (!licenseFile) {
      throw new Error(`${name} has no license file`);
    }
    const text = (await readFile(new URL(licenseFile, directory), 'utf8')).trim();
    sections.push(`${name} ${manifest.version} (${manifest.license})\n\n${text}`);
  }
  return `Third-party software bundled into editor.js\n\n${sections.join('\n\n' + '-'.repeat(72) + '\n\n')}\n`;
}

let outdated = false;
for (const [name, content] of Object.entries(files)) {
  const output = new URL(name, assets);
  if (check) {
    if ((await readFile(output, 'utf8').catch(() => '')) !== content) {
      console.error(`assets/editor/${name} is out of date: run \`npm run build\` in tool/editor.`);
      outdated = true;
    }
  } else {
    await writeFile(output, content);
    console.log(`Wrote assets/editor/${name} (${Math.round(content.length / 1024)} kB).`);
  }
}
if (outdated) {
  process.exit(1);
}
if (check) {
  console.log('assets/editor is up to date.');
}
