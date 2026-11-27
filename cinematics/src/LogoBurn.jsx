// Ouverture : le logo d'Ashura se dessine au pinceau sur un papier noir (anneau, visage, nom), brille,
// puis le papier brûle : des trous s'ouvrent, leurs bords deviennent incandescents (orange → jaune), des braises
// s'envolent, et la scène suivante apparaît à travers. Dessin sur <canvas>, image par image (déterministe).
import React, { useEffect, useLayoutEffect, useRef, useState } from 'react';
import { continueRender, delayRender, staticFile, useCurrentFrame } from 'remotion';
import { W, H } from './Scenery';

export const DRAW_END = 165;
export const BURN_START = 215;
export const BURN_END = 335;

// --- bruit déterministe (pour les bords du papier qui brûle) ------------------------------------
function hash(x, y) {
	let h = (x * 374761393 + y * 668265263) | 0;
	h = (h ^ (h >>> 13)) * 1274126177;
	return ((h ^ (h >>> 16)) >>> 0) / 4294967296;
}
function vnoise(x, y) {
	const xi = Math.floor(x), yi = Math.floor(y);
	const xf = x - xi, yf = y - yi;
	const u = xf * xf * (3 - 2 * xf), v = yf * yf * (3 - 2 * yf);
	const a = hash(xi, yi), b = hash(xi + 1, yi), c = hash(xi, yi + 1), d = hash(xi + 1, yi + 1);
	return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v;
}
function fbm(x, y) {
	return vnoise(x, y) * 0.55 + vnoise(x * 2.1, y * 2.1) * 0.28 + vnoise(x * 4.3, y * 4.3) * 0.17;
}
const MW = 640, MH = 288; // résolution du masque de brûlure
const SEEDS = [[0.52, 0.55, 0.0], [0.18, 0.3, 0.12], [0.85, 0.25, 0.2], [0.3, 0.85, 0.25], [0.9, 0.8, 0.3]];
let FIELD = null;
function field() {
	if (FIELD) return FIELD;
	FIELD = new Float32Array(MW * MH);
	for (let y = 0; y < MH; y++) {
		for (let x = 0; x < MW; x++) {
			const px = x / MW, py = y / MH;
			let d = 9;
			for (const s of SEEDS) {
				const dd = Math.hypot((px - s[0]) * (W / H), py - s[1]) / 1.6 + s[2];
				d = Math.min(d, dd);
			}
			FIELD[y * MW + x] = d * 0.72 + fbm(x / 44, y / 44) * 0.38;
		}
	}
	return FIELD;
}

// Traits de pinceau qui révèlent le logo (coordonnées dans l'image du logo, 460 × 567).
function strokes() {
	const out = [];
	const ring = [];
	for (let i = 0; i <= 64; i++) {
		const a = -1.9 + (i / 64) * Math.PI * 2.05;
		ring.push([230 + Math.cos(a) * 192, 205 + Math.sin(a) * 192]);
	}
	out.push({ pts: ring, w: 64, from: 0, to: 55 });
	const face = [];
	for (let r = 0; r < 12; r++) {
		const y = 20 + r * 30;
		face.push(r % 2 ? [370, y] : [90, y]);
		face.push(r % 2 ? [90, y + 15] : [370, y + 15]);
	}
	out.push({ pts: face, w: 46, from: 45, to: 115 });
	out.push({ pts: [[20, 400], [450, 395], [450, 440], [15, 445], [20, 480], [450, 478]], w: 50, from: 108, to: 145 });
	out.push({ pts: [[60, 538], [410, 538]], w: 40, from: 140, to: DRAW_END });
	return out;
}
const STROKES = strokes();

function partial(ctx, pts, p) {
	let total = 0;
	const seg = [];
	for (let i = 1; i < pts.length; i++) {
		const l = Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]);
		seg.push(l);
		total += l;
	}
	let left = total * p;
	ctx.beginPath();
	ctx.moveTo(pts[0][0], pts[0][1]);
	for (let i = 1; i < pts.length && left > 0; i++) {
		const k = Math.min(1, left / seg[i - 1]);
		ctx.lineTo(pts[i - 1][0] + (pts[i][0] - pts[i - 1][0]) * k, pts[i - 1][1] + (pts[i][1] - pts[i - 1][1]) * k);
		left -= seg[i - 1];
	}
	ctx.stroke();
}

function useImages(srcs) {
	const [imgs, setImgs] = useState(null);
	const [handle] = useState(() => delayRender('images du logo'));
	useEffect(() => {
		let n = 0;
		const list = srcs.map((s) => {
			const im = new Image();
			im.onload = () => {
				n++;
				if (n === srcs.length) {
					setImgs(list);
					continueRender(handle);
				}
			};
			im.src = staticFile(s);
			return im;
		});
	}, []);
	return imgs;
}

export const LogoBurn = () => {
	const frame = useCurrentFrame();
	const ref = useRef(null);
	const imgs = useImages(['logo_paper.jpg', 'logo_ashura.png']);
	useLayoutEffect(() => {
		const cv = ref.current;
		if (!cv || !imgs) return;
		const ctx = cv.getContext('2d');
		const [paper, logo] = imgs;
		ctx.clearRect(0, 0, W, H);
		// papier noir
		ctx.globalCompositeOperation = 'source-over';
		ctx.drawImage(paper, 0, 0, paper.width, paper.height, 0, 0, W, W * paper.height / paper.width);
		ctx.fillStyle = 'rgba(8,6,6,0.55)';
		ctx.fillRect(0, 0, W, H);
		// logo révélé par les traits de pinceau
		const ls = 440 / logo.height;
		const lx = W / 2 - logo.width * ls / 2, ly = H / 2 - logo.height * ls / 2 - 4;
		const off = document.createElement('canvas');
		off.width = logo.width;
		off.height = logo.height;
		const oc = off.getContext('2d');
		oc.lineCap = 'round';
		oc.lineJoin = 'round';
		oc.strokeStyle = '#fff';
		for (const s of STROKES) {
			const p = Math.max(0, Math.min(1, (frame - s.from) / (s.to - s.from)));
			if (p <= 0) continue;
			oc.lineWidth = s.w;
			partial(oc, s.pts, p);
		}
		oc.globalCompositeOperation = 'source-in';
		oc.drawImage(logo, 0, 0);
		const pulse = frame > DRAW_END ? 0.25 + 0.25 * Math.sin((frame - DRAW_END) / 9) : 0;
		if (pulse > 0) {
			ctx.shadowColor = 'rgba(255,40,30,0.9)';
			ctx.shadowBlur = 30 * pulse;
		}
		ctx.drawImage(off, lx, ly, logo.width * ls, logo.height * ls);
		ctx.shadowBlur = 0;
		// brûlure
		if (frame < BURN_START) return;
		const T = ((frame - BURN_START) / (BURN_END - BURN_START)) * 1.25 - 0.05;
		const f = field();
		const mask = document.createElement('canvas');
		mask.width = MW;
		mask.height = MH;
		const mc = mask.getContext('2d');
		const id = mc.createImageData(MW, MH);
		const glow = mc.createImageData(MW, MH);
		for (let i = 0; i < MW * MH; i++) {
			const e = f[i] - T;
			const o = i * 4;
			if (e < 0) {
				id.data[o + 3] = 255; // brûlé : trou
			} else if (e < 0.012) {
				const k = 1 - e / 0.012; // bord incandescent (fin)
				glow.data[o] = 255;
				glow.data[o + 1] = 120 + 135 * k;
				glow.data[o + 2] = 40 + 120 * k * k;
				glow.data[o + 3] = 255;
			} else if (e < 0.05) {
				glow.data[o] = 30; glow.data[o + 1] = 16; glow.data[o + 2] = 8;
				glow.data[o + 3] = Math.round(210 * (1 - (e - 0.012) / 0.038)); // papier roussi
			}
		}
		mc.putImageData(id, 0, 0);
		ctx.globalCompositeOperation = 'destination-out';
		ctx.imageSmoothingEnabled = true;
		ctx.imageSmoothingQuality = 'high';
		ctx.drawImage(mask, 0, 0, W, H);
		ctx.globalCompositeOperation = 'source-atop';
		const g2 = document.createElement('canvas');
		g2.width = MW;
		g2.height = MH;
		g2.getContext('2d').putImageData(glow, 0, 0);
		ctx.drawImage(g2, 0, 0, W, H);
		// lueur et braises
		ctx.globalCompositeOperation = 'lighter';
		ctx.filter = 'blur(5px)';
		ctx.globalAlpha = 0.55;
		ctx.drawImage(g2, 0, 0, W, H);
		ctx.globalAlpha = 1;
		ctx.filter = 'none';
		for (let k = 0; k < 140; k++) {
			const born = BURN_START + hash(k, 7) * (BURN_END - BURN_START);
			const age = (frame - born) / 40;
			if (age < 0 || age > 1) continue;
			const x0 = hash(k, 3) * W, y0 = hash(k, 5) * H;
			const x = x0 + Math.sin(age * 6 + k) * 18;
			const y = y0 - age * 140;
			ctx.fillStyle = `rgba(255,${150 + 100 * (1 - age)},60,${1 - age})`;
			ctx.beginPath();
			ctx.arc(x, y, 1.5 + 2 * (1 - age), 0, Math.PI * 2);
			ctx.fill();
		}
		ctx.globalCompositeOperation = 'source-over';
	}, [frame, imgs]);
	return <canvas ref={ref} width={W} height={H} style={{ position: 'absolute', inset: 0 }} />;
};
