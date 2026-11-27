// Rendu des cinématiques : node render.mjs [Intro|Chapitre-N|all] [--still image]
// Sortie : out/<id>.mp4 (puis converti en .ogv Theora pour Godot par tools/cinematics_export.sh).
import { bundle } from '@remotion/bundler';
import { renderMedia, renderStill, selectComposition } from '@remotion/renderer';
import path from 'node:path';
import fs from 'node:fs';

// musiques et police copiées depuis le jeu (pas de doublon dans le dépôt)
for (const f of ['ouverture_heroique.ogg', 'festin.ogg', 'cinq_armees.ogg', 'achille.ogg']) {
	fs.copyFileSync(`../assets/audio/music/${f}`, `public/${f}`);
}
for (const f of ['Cinzel-Bold.ttf', 'Cinzel-Regular.ttf']) fs.copyFileSync(`../assets/fonts/${f}`, `public/${f}`);
fs.mkdirSync('out', { recursive: true });

const CHROME = '/opt/pw-browsers/chromium_headless_shell-1243/chrome-headless-shell-linux64/chrome-headless-shell';
const which = process.argv[2] || 'all';
const still = process.argv.indexOf('--still');
const serveUrl = await bundle({ entryPoint: path.resolve('src/index.js') });
const ids = which === 'all' ? ['Intro', ...[1, 2, 3, 4, 5, 6, 7].map((n) => `Chapitre-${n}`)] : [which];
for (const id of ids) {
	const composition = await selectComposition({ serveUrl, id, browserExecutable: CHROME });
	if (still > 0) {
		const frame = parseInt(process.argv[still + 1] || '0', 10);
		await renderStill({ composition, serveUrl, output: `out/${id}-${frame}.png`, frame, browserExecutable: CHROME });
		console.log('image', id, frame);
		continue;
	}
	const t0 = Date.now();
	await renderMedia({
		composition, serveUrl, codec: 'h264', outputLocation: `out/${id}.mp4`, browserExecutable: CHROME,
		concurrency: 4, crf: 18,
		
	});
	console.log(`\n${id} rendu en ${Math.round((Date.now() - t0) / 1000)} s`);
}
