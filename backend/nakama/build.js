const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const srcFile = path.join(__dirname, 'src', 'main.ts');
const outDir = path.join(__dirname, 'data', 'modules');
const outFile = path.join(outDir, 'index.js');

if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir, { recursive: true });
}

console.log('[Build] Bundling Nakama TypeScript modules with esbuild...');

try {
    execSync(`cmd.exe /c npx -y esbuild "${srcFile}" --bundle --outfile="${outFile}" --target=es2020 --format=iife`, {
        cwd: __dirname,
        stdio: 'inherit'
    });

    // Append top-level InitModule binding for Nakama Goja engine
    let content = fs.readFileSync(outFile, 'utf8');
    content += '\nvar InitModule = globalThis.InitModule;\n';
    fs.writeFileSync(outFile, content, 'utf8');

    console.log(`[Build] Successfully compiled to ${outFile}`);
} catch (err) {
    console.error('[Build Error]', err);
    process.exit(1);
}
