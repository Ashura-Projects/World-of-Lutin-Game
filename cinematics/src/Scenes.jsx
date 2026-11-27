// Scènes dessinées de la cinématique d'ouverture et des chapitres. Chaque scène reçoit f (image locale) et dur.
import React from 'react';
import { interpolate } from 'remotion';
import { Lutin, Orc } from './Characters';
import { Sky, Sun, Cloud, Hill, hillY, Pine, RoundTree, House, Castle, Field, Smoke, Caption, Fade, W, H } from './Scenery';

const CLANS = [
	{ tunic: '#2c4a96', hat: '#8c4030', flag: '#2c4a96', skin: '#4f78b0' },
	{ tunic: '#7a5a2a', hat: '#c49e54', flag: '#e8c440', skin: '#d8b84a' },
	{ tunic: '#5a2a2a', hat: '#3a2a20', flag: '#d04848', skin: '#c0505e' },
	{ tunic: '#3e6a3a', hat: '#6a4428', flag: '#7ad060', skin: '#8fd27a' },
];

const Svg = ({ children }) => (
	<svg width={W} height={H} viewBox={`0 0 ${W} ${H}`} style={{ position: 'absolute', inset: 0 }}>{children}</svg>
);

const Forest = ({ base, amp, freq, phase, shift, from, to, step, s, color, t }) =>
	Array.from({ length: Math.floor((to - from) / step) }).map((_, i) => {
		const x = from + i * step + ((i * 37) % 13);
		return <Pine key={i} x={x} y={hillY(x, base, amp, freq, phase, shift) + 4} s={s * (0.8 + ((i * 7) % 5) / 12)} color={color} t={t} />;
	});

// 1. Les lutins arrivent dans la vallée à l'aube.
export const Arrival = ({ f, dur , captions = null }) => {
	const t = f / 30;
	const pan = f * 0.6;
	const sunY = interpolate(f, [0, dur], [330, 170], { extrapolateRight: 'clamp' });
	return (
		<>
			<Svg>
				<Sky top="#6a86c0" bottom="#ffd9a0" id="sky1" />
				<Sun x={900} y={sunY} r={44} color="#fff0b0" glow={0.6} />
				<Cloud x={200 + t * 8} y={90} s={1.2} />
				<Cloud x={800 + t * 5} y={60} s={0.8} opacity={0.6} />
				<Hill base={330} amp={70} freq={0.004} phase={1} color="#8a9ac0" shift={pan * 0.15} />
				<Hill base={390} amp={40} freq={0.006} phase={2} color="#6a9a58" shift={pan * 0.35} />
				<Forest base={390} amp={40} freq={0.006} phase={2} shift={pan * 0.35} from={40} to={1280} step={70} s={0.55} color="#4a7a4e" t={t} />
				<Hill base={470} amp={25} freq={0.004} phase={4} color="#7aac5a" shift={pan} />
				{[0, 1, 2, 3, 4, 5, 6].map((i) => {
					const x = -160 + t * 46 - i * 58;
					const c = CLANS[0];
					return (
						<Lutin key={i} x={x} y={hillY(x, 470, 25, 0.004, 4, pan) + 2} s={1.15} t={t} walk={1} seed={i * 1.7}
							tunic={i % 2 ? '#5a6a48' : c.tunic} hat={i % 3 ? c.hat : '#6a4428'} pose={i === 0 ? 'banner' : 'idle'} flag={c.flag} />
					);
				})}
				<RoundTree x={1180} y={hillY(1180, 470, 25, 0.004, 4, pan) + 4} s={1.4} />
			</Svg>
			{(captions || [["Il y a bien longtemps, des lutins cherchaient un foyer…", 30, 210], ["…et trouvèrent une vallée oubliée.", 270, 240]]).map(([text, from, d], i) => (
				<Caption key={i} text={text} frame={f} from={from} dur={d} />
			))}
			<Fade frame={f} dur={dur} />
		</>
	);
};

// 2. Les clans s'unissent et bâtissent leurs villages.
export const Building = ({ f, dur , captions = null }) => {
	const t = f / 30;
	const meet = Math.min(1, f / 170);
	return (
		<>
			<Svg>
				<Sky top="#78b4e6" bottom="#e8f4ff" id="sky2" />
				<Sun x={1100} y={90} r={38} color="#fff6c8" glow={0.4} />
				<Cloud x={300 + t * 10} y={80} s={1} />
				<Hill base={300} amp={40} freq={0.005} phase={0.5} color="#8aaa70" />
				{[[180, 0.4], [420, 0.45], [980, 0.42], [1150, 0.38]].map(([x, s], i) => (
					<House key={i} x={x} y={hillY(x, 300, 40, 0.005, 0.5) + 3} s={s} progress={(f - 150 - i * 40) / 60}
						wall={i % 2 ? '#a8a49c' : '#b08a58'} flag={CLANS[(i % 3) + 1].flag} t={t} />
				))}
				<Hill base={420} amp={18} freq={0.004} phase={3} color="#86b860" />
				<Field x={60} y={430} w={180} h={40} color="#e0c050" />
				<Field x={1040} y={440} w={180} h={36} color="#a8c050" />
				{[0, 1, 2].map((k) => (
					<House key={k} x={[300, 960, 1130][k]} y={hillY([300, 960, 1130][k], 420, 18, 0.004, 3) + 4} s={1.05}
						progress={(f - 200 - k * 60) / 110} wall={['#b08a58', '#a8a49c', '#b8946a'][k]} roof={['#c8a84a', '#8c4a30', '#c8a84a'][k]}
						flag={CLANS[k + 1].flag} t={t} glow={0} />
				))}
				{[0, 1, 2].map((k) => (f > 330 + k * 60 ? <Smoke key={k} x={[300, 960, 1130][k] + 16} y={hillY([300, 960, 1130][k], 420, 18, 0.004, 3) - 60} t={t + k} /> : null))}
				{CLANS.slice(1).map((c, k) => {
					const sx = [-120, 640, 1400][k];
					const ex = [520, 640, 760][k];
					const x = sx + (ex - sx) * meet;
					const moving = meet < 1;
					return [0, 1].map((j) => (
						<Lutin key={`${k}${j}`} x={x + (j - 0.5) * 50 + (moving ? 0 : 0)} y={(f < 170 ? 500 : 500) + j * 10} s={1.1} t={t}
							walk={moving ? 1 : 0} flip={k === 2} seed={k * 3 + j}
							pose={!moving ? (f < 230 ? 'cheer' : 'hammer') : j === 0 ? 'banner' : 'idle'}
							tunic={c.tunic} hat={c.hat} skin={c.skin} flag={c.flag} />
					));
				})}
			</Svg>
			{(captions || [["Les clans se rencontrèrent et s'unirent…", 20, 190], ["…et bâtirent ensemble leurs villages.", 230, 230]]).map(([text, from, d], i) => (
				<Caption key={i} text={text} frame={f} from={from} dur={d} />
			))}
			<Fade frame={f} dur={dur} />
		</>
	);
};

// 3. La guerre : les orcs chargent, les lutins tiennent la ligne (lances, fusils, catapulte).
export const War = ({ f, dur, victory = false , captions = null }) => {
	const t = f / 30;
	const shake = f > 200 && f < 420 ? Math.sin(f * 1.7) * 3 : 0;
	const charge = Math.min(1, f / 220);
	return (
		<>
			<Svg>
				<g transform={`translate(${shake},0)`}>
					<Sky top="#3a1a22" bottom="#d8603a" id="sky3" />
					<Sun x={640} y={360} r={70} color="#ff8a4a" glow={0.5} />
					<Hill base={360} amp={50} freq={0.005} phase={1} color="#4a3a40" />
					<Castle x={150} y={hillY(150, 360, 50, 0.005, 1) + 6} s={0.7} flag="#2c4a96" t={t} stone="#7a7680" />
					<Smoke x={900} y={330} t={t} n={6} color="#3a3034" size={2.2} />
					<Smoke x={300} y={300} t={t + 2} n={5} color="#3a3034" size={1.6} />
					<Hill base={480} amp={14} freq={0.004} phase={2} color="#5a4a3a" />
					{Array.from({ length: 9 }).map((_, i) => {
						const x = 1400 - charge * 760 + (i % 3) * 70 + Math.floor(i / 3) * 30;
						return <Orc key={i} x={x} y={470 + Math.floor(i / 3) * 22} s={1.05} t={t} walk={charge < 1 ? 1.2 : 0} swing={charge >= 1} seed={i} />;
					})}
					{Array.from({ length: 8 }).map((_, i) => {
						const musket = i % 2 === 1;
						const x = 320 + (i % 4) * 58 + Math.floor(i / 4) * -30;
						const fire = musket && Math.sin(t * 3 + i) > 0.97;
						return (
							<g key={i}>
								<Lutin x={x} y={478 + Math.floor(i / 4) * 22} s={1.1} t={t} pose={musket ? 'musket' : 'spear'} helmet seed={i}
									tunic="#22346e" flag="#2c4a96" />
								{fire && <circle cx={x + 52} cy={478 + Math.floor(i / 4) * 22 - 44} r={12} fill="#ffe08a" opacity={0.9} />}
								{musket && <Smoke x={x + 56} y={478 + Math.floor(i / 4) * 22 - 44} t={t + i} n={2} color="#c8c0b8" size={0.5} />}
							</g>
						);
					})}
					{(() => {
						const k = (f % 90) / 90;
						const x = 200 + k * 700, y = 300 - Math.sin(k * Math.PI) * 220;
						return f > 60 ? <circle cx={x} cy={y} r={10} fill="#6a6a6a" stroke="#1e1a24" strokeWidth={2} /> : null;
					})()}
					{victory && f > dur * 0.6 && <rect x={0} y={0} width={W} height={H} fill="#ffe08a" opacity={0.15} />}
				</g>
			</Svg>
			{(captions || [["Mais la guerre vint : orcs et bandits menacèrent la vallée.", 20, 250], ["Les lutins défendirent leurs foyers.", 300, 240]]).map(([text, from, d], i) => (
				<Caption key={i} text={text} frame={f} from={from} dur={d} />
			))}
			<Fade frame={f} dur={dur} />
		</>
	);
};

// 4. La diplomatie : deux chefs se serrent la main sous les étendards.
export const Diplomacy = ({ f, dur , captions = null }) => {
	const t = f / 30;
	return (
		<>
			<Svg>
				<Sky top="#4a3a6a" bottom="#f0a070" id="sky4" />
				<Hill base={380} amp={30} freq={0.004} phase={2} color="#6a7a58" />
				<polygon points="440,420 640,150 840,420" fill="#e4dcc8" stroke="#1e1a24" strokeWidth={3} />
				<polygon points="590,420 640,300 690,420" fill="#3a2a20" />
				{[0, 1, 2, 3].map((i) => (
					<g key={i}>
						<rect x={220 + i * 260} y={180} width={4} height={240} fill="#5a3e28" />
						<path d={`M 224 ${180} Q ${250} ${186 + Math.sin(t * 4 + i) * 6} ${276} 180 L 276 260 Q 250 ${266 + Math.sin(t * 4 + i + 1) * 6} 224 260 Z`}
							transform={`translate(${i * 260},0)`} fill={CLANS[i].flag} stroke="#1e1a24" strokeWidth={2} />
					</g>
				))}
				<rect x={520} y={430} width={240} height={14} fill="#8a6440" stroke="#1e1a24" strokeWidth={2} />
				<rect x={600} y={420} width={80} height={10} fill="#f0e6c8" stroke="#1e1a24" strokeWidth={1.5} />
				<Lutin x={560} y={500} s={1.6} t={t} pose={f > 90 ? 'shake' : 'idle'} tunic="#2c4a96" hat="#8c4030" />
				<Lutin x={720} y={500} s={1.6} t={t} flip pose={f > 90 ? 'shake' : 'idle'} tunic="#7a5a2a" hat="#c49e54" skin="#d8b84a" />
			</Svg>
			{(captions || [["Par l'épée et par la parole…", 20, 170], ["…les peuples de la vallée scellèrent des alliances.", 210, 170]]).map(([text, from, d], i) => (
				<Caption key={i} text={text} frame={f} from={from} dur={d} />
			))}
			<Fade frame={f} dur={dur} />
		</>
	);
};

// 5. La vallée prospère : les lutins, de dos, regardent leur royaume au coucher du soleil ; puis le titre.
export const Prosperity = ({ f, dur, title = true }) => {
	const t = f / 30;
	const zoom = interpolate(f, [0, dur], [1, 1.08]);
	const titleA = title ? Math.max(0, Math.min(1, (f - (dur - 240)) / 40)) : 0;
	return (
		<>
			<Svg>
				<g transform={`translate(${W / 2},${H / 2}) scale(${zoom}) translate(${-W / 2},${-H / 2})`}>
					<Sky top="#e88a5a" bottom="#ffe0a0" id="sky5" />
					<Sun x={640} y={250} r={60} color="#fff0c0" glow={0.7} />
					<Cloud x={250} y={120} s={1.3} color="#ffd8b0" />
					<Cloud x={1000} y={90} s={1} color="#ffd8b0" />
					<Hill base={300} amp={30} freq={0.004} phase={0} color="#9a8ab0" />
					<Hill base={350} amp={30} freq={0.005} phase={2} color="#8aa870" />
					<Castle x={640} y={hillY(640, 350, 30, 0.005, 2) + 4} s={0.85} flag="#2c4a96" t={t} />
					{[180, 330, 470, 820, 960, 1110].map((x, i) => (
						<House key={i} x={x} y={hillY(x, 350, 30, 0.005, 2) + 3} s={0.5} flag={CLANS[i % 4].flag} t={t} glow={1} />
					))}
					{[180, 470, 960].map((x, i) => <Smoke key={i} x={x + 8} y={hillY(x, 350, 30, 0.005, 2) - 26} t={t + i} size={0.6} />)}
					<path d="M 0 420 Q 400 380 640 400 T 1280 390 L 1280 440 Q 900 430 640 440 T 0 460 Z" fill="#6aa8d8" stroke="#3a6a98" strokeWidth={2} />
					<Field x={200} y={460} w={200} h={30} color="#e8c850" />
					<Field x={880} y={455} w={220} h={34} color="#c8d860" />
					<Hill base={560} amp={30} freq={0.006} phase={1.5} color="#4a6a3a" />
					{[0, 1, 2, 3, 4].map((i) => (
						<Lutin key={i} x={470 + i * 80} y={hillY(470 + i * 80, 560, 30, 0.006, 1.5) + 4} s={1.35} t={t} back seed={i}
							tunic={CLANS[i % 4].tunic} hat={CLANS[i % 4].hat} skin={CLANS[i % 4].skin} pose={i === 2 ? 'banner' : 'idle'} flag="#2c4a96" />
					))}
				</g>
			</Svg>
			<Caption text="La vallée devint prospère…" frame={f} from={30} dur={190} />
			<Caption text="…mais l'histoire ne fait que commencer." frame={f} from={240} dur={190} />
			{titleA > 0 && (
				<div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', opacity: titleA }}>
					<div style={{ fontFamily: 'Cinzel', fontWeight: 700, fontSize: 92, color: '#f6dc8a', textShadow: '0 4px 0 #6a4020, 0 0 30px rgba(0,0,0,0.7)', letterSpacing: 4 }}>World of Lutins</div>
					<div style={{ fontFamily: 'Cinzel', fontSize: 28, color: '#fff3d0', textShadow: '0 2px 6px #000', marginTop: 6 }}>by Ashura</div>
				</div>
			)}
			<Fade frame={f} dur={dur} edge={20} />
		</>
	);
};
