// Personnages dessinés de World of Lutins (cinématiques) : le lutin (bleu, grands yeux, oreilles pointues,
// chapeau pointu) et l'orc (rouge, grassouillet, défenses). Trait sombre, aplats doux : style « dessin animé ».
import React from 'react';

const INK = '#1e1a24';

// Lutin vu de profil (regarde à droite ; flip = à gauche). walk : vitesse de marche (0 = arrêté).
// pose : 'idle' | 'walk' | 'hammer' | 'spear' | 'musket' | 'banner' | 'cheer' | 'shake' | 'look'
export const Lutin = ({
	x, y, s = 1, t = 0, walk = 0, flip = false, tunic = '#5a6a48', hat = '#8c4030',
	skin = '#4f78b0', pose = 'idle', flag = '#2c4a96', helmet = false, back = false, seed = 0, beard = false,
}) => {
	const ph = t * 9 + seed;
	const sw = walk ? Math.sin(ph) : 0;
	const bob = walk ? Math.abs(Math.sin(ph)) * 2.5 : Math.sin(t * 2 + seed) * 0.8;
	let armR = sw * 30;
	let armL = -sw * 30;
	if (pose === 'hammer') armR = -70 + Math.max(0, Math.sin(t * 7 + seed)) * 110;
	if (pose === 'spear') armR = -20;
	if (pose === 'musket') { armR = -82; armL = -70; }
	if (pose === 'banner') armR = -150;
	if (pose === 'cheer') { armR = -150 + Math.sin(t * 8 + seed) * 15; armL = 150 - Math.sin(t * 8 + seed) * 15; }
	if (pose === 'shake') armR = -55 + Math.sin(t * 10) * 10;
	if (pose === 'staff') armL = -20;
	const skinD = shade(skin, -0.22);
	return (
		<g transform={`translate(${x},${y - bob}) scale(${flip ? -s : s},${s})`}>
			<ellipse cx={0} cy={bob + 1} rx={16} ry={4} fill="rgba(0,0,0,0.22)" />
			{/* jambes */}
			<g transform={`rotate(${-sw * 28},0,-20)`}>
				<rect x={-6} y={-20} width={8} height={18} rx={3} fill="#464052" stroke={INK} strokeWidth={1.5} />
				<ellipse cx={0} cy={-2} rx={7} ry={4} fill="#5c3a24" stroke={INK} strokeWidth={1.5} />
			</g>
			<g transform={`rotate(${sw * 28},0,-20)`}>
				<rect x={-2} y={-20} width={8} height={18} rx={3} fill="#3c3646" stroke={INK} strokeWidth={1.5} />
				<ellipse cx={4} cy={-2} rx={7} ry={4} fill="#4c2e1c" stroke={INK} strokeWidth={1.5} />
			</g>
			{/* bras arrière */}
			<g transform={`rotate(${armL},-2,-40)`}>
				<rect x={-6} y={-42} width={8} height={20} rx={4} fill={shade(tunic, -0.15)} stroke={INK} strokeWidth={1.5} />
				<circle cx={-2} cy={-22} r={4.5} fill={skinD} stroke={INK} strokeWidth={1.5} />
				{pose === 'staff' && (
					<g>
						<rect x={-4} y={-80} width={4} height={84} rx={2} fill="#6a4428" stroke={INK} strokeWidth={1} />
						<circle cx={-2} cy={-84} r={7} fill="#8ad0f0" stroke={INK} strokeWidth={1.5} />
					</g>
				)}
			</g>
			{/* corps */}
			<ellipse cx={0} cy={-34} rx={15} ry={18} fill={tunic} stroke={INK} strokeWidth={2} />
			<path d="M -12 -40 Q 0 -30 12 -40" stroke={shade(tunic, 0.2)} strokeWidth={3} fill="none" />
			<rect x={-14} y={-27} width={28} height={4} rx={2} fill="#784c2c" stroke={INK} strokeWidth={1} />
			{/* tête */}
			{!back && <polygon points="-14,-64 -30,-58 -15,-55" fill={skin} stroke={INK} strokeWidth={1.5} />}
			<polygon points="14,-64 30,-58 15,-55" fill={skin} stroke={INK} strokeWidth={1.5} />
			<circle cx={0} cy={-62} r={19} fill={skin} stroke={INK} strokeWidth={2} />
			{!back && (
				<>
					<ellipse cx={7} cy={-62} rx={4.2} ry={6} fill="#181622" />
					<ellipse cx={-4} cy={-62} rx={3.6} ry={5.6} fill="#181622" />
					<circle cx={8.5} cy={-64.5} r={1.5} fill="#fff" />
					<circle cx={-2.6} cy={-64.2} r={1.3} fill="#fff" />
					<ellipse cx={15} cy={-58} rx={4} ry={3} fill={skinD} />
					<ellipse cx={11} cy={-54} rx={3.5} ry={2} fill="#c47890" opacity={0.7} />
					<path d={pose === 'cheer' ? 'M 2 -52 Q 7 -47 12 -52' : 'M 4 -51 Q 7 -49 10 -51'} stroke={INK} strokeWidth={1.4} fill="none" />
				</>
			)}
			{beard && !back && (
				<path d="M -6 -56 Q 4 -46 18 -54 Q 20 -30 6 -18 Q -4 -30 -6 -56 Z" fill="#eeeae0" stroke={INK} strokeWidth={1.5} />
			)}
			{/* chapeau pointu (ou casque des soldats) */}
			{helmet ? (
				<g>
					<path d="M -19 -68 Q 0 -94 19 -68 Z" fill="#8a8e96" stroke={INK} strokeWidth={2} />
					<rect x={-22} y={-70} width={44} height={5} rx={2} fill="#6a6e76" stroke={INK} strokeWidth={1.5} />
					<path d="M 0 -88 L 4 -100 L 8 -88" fill={flag} stroke={INK} strokeWidth={1} />
				</g>
			) : (
				<g transform={`rotate(${-8 + Math.sin(t * 3 + seed) * 4},0,-75)`}>
					<path d="M -20 -73 Q -2 -78 20 -73 L 6 -112 Q 2 -118 -2 -112 Z" fill={hat} stroke={INK} strokeWidth={2} />
					<ellipse cx={0} cy={-73} rx={23} ry={5} fill={shade(hat, -0.15)} stroke={INK} strokeWidth={1.5} />
					<circle cx={2} cy={-113} r={3.5} fill="#e6dcc8" stroke={INK} strokeWidth={1} />
				</g>
			)}
			{/* bras avant + outil */}
			<g transform={`rotate(${armR},2,-40)`}>
				<rect x={-2} y={-42} width={8} height={20} rx={4} fill={tunic} stroke={INK} strokeWidth={1.5} />
				<circle cx={2} cy={-22} r={4.8} fill={skin} stroke={INK} strokeWidth={1.5} />
				{pose === 'hammer' && (
					<g>
						<rect x={0} y={-24} width={4} height={22} fill="#80583a" stroke={INK} strokeWidth={1} />
						<rect x={-6} y={-6} width={16} height={8} rx={1} fill="#8a8e96" stroke={INK} strokeWidth={1.5} />
					</g>
				)}
				{pose === 'spear' && (
					<g>
						<rect x={0} y={-70} width={3.5} height={66} fill="#80583a" stroke={INK} strokeWidth={1} />
						<polygon points="-2,-70 1.7,-86 5.5,-70" fill="#c8ccd4" stroke={INK} strokeWidth={1} />
					</g>
				)}
				{pose === 'musket' && (
					<g transform="rotate(82,2,-22)">
						<rect x={-6} y={-26} width={14} height={6} rx={2} fill="#6a4428" stroke={INK} strokeWidth={1} />
						<rect x={8} y={-25} width={34} height={3.5} fill="#5a5e66" stroke={INK} strokeWidth={1} />
					</g>
				)}
				{pose === 'banner' && (
					<g>
						<rect x={0} y={-90} width={3.5} height={86} fill="#80583a" stroke={INK} strokeWidth={1} />
						<path d={`M 3 -90 Q ${22} ${-86 + Math.sin(t * 6) * 4} 40 -90 L 40 -64 Q 22 ${-60 + Math.sin(t * 6 + 1) * 4} 3 -64 Z`}
							fill={flag} stroke={INK} strokeWidth={1.5} />
					</g>
				)}
			</g>
		</g>
	);
};

// Orc : rouge, gros ventre, petites cornes et défenses, gourdin.
export const Orc = ({ x, y, s = 1, t = 0, walk = 0, flip = true, seed = 0, swing = false }) => {
	const ph = t * 8 + seed;
	const sw = walk ? Math.sin(ph) : 0;
	const bob = walk ? Math.abs(Math.sin(ph)) * 3 : 0;
	const club = swing ? -80 + Math.max(0, Math.sin(t * 6 + seed)) * 120 : -30 + sw * 20;
	const skin = '#c0483a';
	return (
		<g transform={`translate(${x},${y - bob}) scale(${flip ? -s : s},${s})`}>
			<ellipse cx={0} cy={bob + 1} rx={22} ry={5} fill="rgba(0,0,0,0.25)" />
			<g transform={`rotate(${-sw * 22},0,-22)`}><rect x={-9} y={-24} width={11} height={22} rx={4} fill="#5a3a24" stroke={INK} strokeWidth={2} /></g>
			<g transform={`rotate(${sw * 22},0,-22)`}><rect x={-1} y={-24} width={11} height={22} rx={4} fill="#4a2e1c" stroke={INK} strokeWidth={2} /></g>
			<ellipse cx={0} cy={-42} rx={25} ry={24} fill={skin} stroke={INK} strokeWidth={2.4} />
			<ellipse cx={4} cy={-36} rx={15} ry={14} fill="#d86a5a" />
			<rect x={-24} y={-28} width={48} height={10} rx={3} fill="#5a3a24" stroke={INK} strokeWidth={1.5} />
			<circle cx={4} cy={-74} r={17} fill={skin} stroke={INK} strokeWidth={2.4} />
			<path d="M -8 -88 L -14 -100 L -2 -90" fill="#e8dcc0" stroke={INK} strokeWidth={1.5} />
			<path d="M 10 -89 L 14 -101 L 18 -88" fill="#e8dcc0" stroke={INK} strokeWidth={1.5} />
			<path d="M 2 -80 L 16 -77" stroke={INK} strokeWidth={2.5} />
			<circle cx={11} cy={-75} r={2.6} fill="#ffd24a" stroke={INK} strokeWidth={1} />
			<path d="M 8 -64 L 10 -58 L 12 -64 M 15 -64 L 17 -59 L 19 -64" fill="#f4ecd8" stroke={INK} strokeWidth={1} />
			<path d="M 6 -65 Q 13 -61 21 -66" stroke={INK} strokeWidth={1.6} fill="none" />
			<g transform={`rotate(${club},14,-50)`}>
				<rect x={10} y={-52} width={10} height={22} rx={5} fill={skin} stroke={INK} strokeWidth={2} />
				<path d="M 13 -32 L 10 -2 Q 15 6 22 -2 L 19 -32 Z" fill="#6a4428" stroke={INK} strokeWidth={2} />
				<circle cx={16} cy={-6} r={2} fill="#8a8e96" />
			</g>
		</g>
	);
};

export function shade(hex, amt) {
	const n = parseInt(hex.replace('#', ''), 16);
	let r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255;
	const f = (c) => Math.max(0, Math.min(255, Math.round(amt < 0 ? c * (1 + amt) : c + (255 - c) * amt)));
	return `rgb(${f(r)},${f(g)},${f(b)})`;
}
