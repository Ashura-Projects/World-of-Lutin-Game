// Décors dessinés : ciel en dégradé, soleil, nuages, collines en couches (parallaxe), sapins et arbres ronds,
// maisons qui se construisent, château, champs, fumées, étendards, légendes. Tout en SVG, trait sombre.
import React from 'react';
import { shade } from './Characters';

const INK = '#1e1a24';
export const W = 1280;
export const H = 576;

export const Sky = ({ top, bottom, id = 'sky' }) => (
	<>
		<defs>
			<linearGradient id={id} x1="0" y1="0" x2="0" y2="1">
				<stop offset="0" stopColor={top} />
				<stop offset="1" stopColor={bottom} />
			</linearGradient>
		</defs>
		<rect x={0} y={0} width={W} height={H} fill={`url(#${id})`} />
	</>
);

export const Sun = ({ x, y, r = 46, color = '#ffe08a', glow = 0.35 }) => (
	<g>
		<circle cx={x} cy={y} r={r * 2.4} fill={color} opacity={glow * 0.35} />
		<circle cx={x} cy={y} r={r * 1.5} fill={color} opacity={glow * 0.6} />
		<circle cx={x} cy={y} r={r} fill={color} />
	</g>
);

export const Cloud = ({ x, y, s = 1, color = '#ffffff', opacity = 0.85 }) => (
	<g transform={`translate(${x},${y}) scale(${s})`} opacity={opacity}>
		<ellipse cx={0} cy={0} rx={60} ry={20} fill={color} />
		<ellipse cx={-28} cy={-10} rx={30} ry={20} fill={color} />
		<ellipse cx={18} cy={-16} rx={34} ry={24} fill={color} />
	</g>
);

// Colline : profil fait de sinus, décalé par la parallaxe (shift en pixels).
export const Hill = ({ base, amp, freq, phase = 0, color, shift = 0, stroke = true }) => {
	let d = `M 0 ${H} `;
	for (let x = 0; x <= W; x += 16) {
		const xx = x + shift;
		const y = base - amp * (0.6 * Math.sin(xx * freq + phase) + 0.4 * Math.sin(xx * freq * 2.3 + phase * 1.7));
		d += `L ${x} ${y.toFixed(1)} `;
	}
	d += `L ${W} ${H} Z`;
	return <path d={d} fill={color} stroke={stroke ? shade(color, -0.35) : 'none'} strokeWidth={2} />;
};

// Hauteur d'une colline à l'abscisse x (pour poser arbres et maisons dessus).
export function hillY(x, base, amp, freq, phase = 0, shift = 0) {
	const xx = x + shift;
	return base - amp * (0.6 * Math.sin(xx * freq + phase) + 0.4 * Math.sin(xx * freq * 2.3 + phase * 1.7));
}

export const Pine = ({ x, y, s = 1, color = '#3e6a4a', t = 0 }) => (
	<g transform={`translate(${x},${y}) scale(${s}) rotate(${Math.sin(t * 1.5 + x) * 1.5})`}>
		<rect x={-4} y={-14} width={8} height={14} fill="#5a3e28" stroke={INK} strokeWidth={1.5} />
		<polygon points="-26,-14 0,-52 26,-14" fill={color} stroke={INK} strokeWidth={2} />
		<polygon points="-20,-38 0,-72 20,-38" fill={shade(color, 0.12)} stroke={INK} strokeWidth={2} />
		<polygon points="-13,-60 0,-88 13,-60" fill={shade(color, 0.22)} stroke={INK} strokeWidth={2} />
	</g>
);

export const RoundTree = ({ x, y, s = 1, color = '#6a9a48' }) => (
	<g transform={`translate(${x},${y}) scale(${s})`}>
		<rect x={-4} y={-22} width={8} height={22} fill="#6a4428" stroke={INK} strokeWidth={1.5} />
		<circle cx={0} cy={-38} r={22} fill={color} stroke={INK} strokeWidth={2} />
		<circle cx={-8} cy={-44} r={9} fill={shade(color, 0.18)} />
	</g>
);

// Maison : progress 0 → 1 = des fondations au toit (on la voit se construire).
export const House = ({ x, y, s = 1, progress = 1, wall = '#b08a58', roof = '#c8a84a', glow = 0, flag = null, t = 0 }) => {
	const p = Math.max(0, Math.min(1, progress));
	const wallH = 34 * Math.min(1, p / 0.7);
	const roofP = Math.max(0, (p - 0.7) / 0.3);
	return (
		<g transform={`translate(${x},${y}) scale(${s})`}>
			<rect x={-30} y={-2} width={60} height={4} fill="#8a8278" stroke={INK} strokeWidth={1.5} />
			<rect x={-26} y={-wallH} width={52} height={wallH} fill={wall} stroke={INK} strokeWidth={2} />
			{wallH > 20 && <rect x={-6} y={-20} width={12} height={20} fill="#4a3020" stroke={INK} strokeWidth={1.5} />}
			{wallH > 28 && <rect x={10} y={-28} width={10} height={9} fill={glow > 0 ? '#ffd27a' : '#2a2a3a'} stroke={INK} strokeWidth={1.5} opacity={1} />}
			{roofP > 0 && (
				<polygon points={`-32,-34 0,${-34 - 30 * roofP} 32,-34`} fill={roof} stroke={INK} strokeWidth={2} />
			)}
			{roofP >= 1 && <rect x={12} y={-60} width={8} height={18} fill="#8a8278" stroke={INK} strokeWidth={1.5} />}
			{flag && roofP >= 1 && (
				<g>
					<rect x={-2} y={-86} width={2.5} height={24} fill="#5a3e28" />
					<path d={`M 0 -86 Q 9 ${-84 + Math.sin(t * 5) * 2} 18 -86 L 18 -76 Q 9 ${-74 + Math.sin(t * 5 + 1) * 2} 0 -76 Z`} fill={flag} stroke={INK} strokeWidth={1} />
				</g>
			)}
		</g>
	);
};

// Château : donjon et deux tours crénelées, étendards.
export const Castle = ({ x, y, s = 1, flag = '#2c4a96', t = 0, stone = '#a8a49c' }) => {
	const tower = (tx, h) => (
		<g>
			<rect x={tx - 16} y={-h} width={32} height={h} fill={stone} stroke={INK} strokeWidth={2} />
			{[0, 1, 2].map((i) => (
				<rect key={i} x={tx - 16 + i * 12} y={-h - 8} width={8} height={8} fill={stone} stroke={INK} strokeWidth={1.5} />
			))}
			<rect x={tx - 4} y={-h + 18} width={8} height={12} fill="#2a2a3a" stroke={INK} strokeWidth={1} />
		</g>
	);
	return (
		<g transform={`translate(${x},${y}) scale(${s})`}>
			<rect x={-60} y={-70} width={120} height={70} fill={shade(stone, -0.08)} stroke={INK} strokeWidth={2} />
			<rect x={-12} y={-34} width={24} height={34} rx={12} fill="#3a2a1e" stroke={INK} strokeWidth={2} />
			{tower(-62, 100)}
			{tower(62, 100)}
			{tower(0, 130)}
			<rect x={-1} y={-170} width={3} height={40} fill="#5a3e28" />
			<path d={`M 1 -170 Q 14 ${-166 + Math.sin(t * 5) * 3} 28 -170 L 28 -154 Q 14 ${-150 + Math.sin(t * 5 + 1) * 3} 1 -154 Z`} fill={flag} stroke={INK} strokeWidth={1.5} />
		</g>
	);
};

export const Field = ({ x, y, w = 120, h = 26, color = '#d8b84a', rows = 5 }) => (
	<g>
		<rect x={x} y={y} width={w} height={h} fill={shade(color, -0.25)} stroke={INK} strokeWidth={1.5} />
		{Array.from({ length: rows }).map((_, i) => (
			<rect key={i} x={x + 3} y={y + 3 + i * (h / rows)} width={w - 6} height={h / rows - 3} fill={color} />
		))}
	</g>
);

export const Smoke = ({ x, y, t = 0, n = 5, color = '#d8d4cc', size = 1 }) => (
	<g>
		{Array.from({ length: n }).map((_, i) => {
			const k = ((t * 0.35 + i / n) % 1);
			return (
				<circle key={i} cx={x + Math.sin(k * 6 + i) * 8 * size + k * 20 * size} cy={y - k * 70 * size}
					r={(5 + k * 14) * size} fill={color} opacity={0.55 * (1 - k)} />
			);
		})}
	</g>
);

// Légende en bas de l'écran (police Cinzel, dorée), qui apparaît et s'efface.
export const Caption = ({ text, frame, from, dur, size = 34 }) => {
	const f = frame - from;
	if (f < 0 || f > dur) return null;
	const a = Math.min(1, f / 15, (dur - f) / 15);
	return (
		<div style={{
			position: 'absolute', left: 0, right: 0, bottom: 34, textAlign: 'center', opacity: a,
			fontFamily: 'Cinzel', fontWeight: 700, fontSize: size, color: '#f0d890',
			textShadow: '0 2px 6px #000, 0 0 18px rgba(0,0,0,0.8)', letterSpacing: 1,
		}}>{text}</div>
	);
};

// Fondu au noir (entrées / sorties de scène).
export const Fade = ({ frame, dur, edge = 15 }) => {
	const a = Math.max(0, 1 - Math.min(frame / edge, (dur - frame) / edge));
	return <div style={{ position: 'absolute', inset: 0, background: '#000', opacity: a }} />;
};
