// Compositions Remotion : « Intro » (ouverture du jeu, ~97 s, musique Heroic Age) et « Chapitre-N » (10 s).
import React from 'react';
import { AbsoluteFill, Audio, Composition, Sequence, staticFile, useCurrentFrame, interpolate } from 'remotion';
import { LogoBurn, BURN_START, BURN_END } from './LogoBurn';
import { Arrival, Building, War, Diplomacy, Prosperity } from './Scenes';
import { Lutin } from './Characters';
import { CHAPTERS } from './chapters';
import { W, H } from './Scenery';

const FONT = `
@font-face { font-family: 'Cinzel'; src: url('${staticFile('Cinzel-Bold.ttf')}'); font-weight: 700; }
@font-face { font-family: 'Cinzel'; src: url('${staticFile('Cinzel-Regular.ttf')}'); font-weight: 400; }
`;

const S = { arrival: Arrival, building: Building, war: War, diplomacy: Diplomacy, prosperity: Prosperity };

// [scène, début, durée] en images (30 / s). La 1re commence pendant que le papier brûle.
const PLAN = [
	['arrival', BURN_START, 570],
	['building', 785, 480],
	['war', 1265, 570],
	['diplomacy', 1835, 390],
	['prosperity', 2225, 685],
];
export const INTRO_FRAMES = 2910;

const Scene = ({ name, dur, captions = null, title = true }) => {
	const f = useCurrentFrame();
	const C = S[name];
	return <C f={f} dur={dur} captions={captions} title={title} />;
};

export const Intro = () => (
	<AbsoluteFill style={{ background: '#000' }}>
		<style>{FONT}</style>
		<Audio src={staticFile('ouverture_heroique.ogg')} />
		{PLAN.map(([name, from, dur]) => (
			<Sequence key={name} from={from} durationInFrames={dur}>
				<Scene name={name} dur={dur} />
			</Sequence>
		))}
		<Sequence from={0} durationInFrames={BURN_END + 5}>
			<LogoBurn />
		</Sequence>
	</AbsoluteFill>
);

// Mini-cinématique de chapitre : bandeau « Chapitre N — titre » puis la scène et sa légende.
const ChapterCard = ({ ch }) => {
	const f = useCurrentFrame();
	const a = interpolate(f, [10, 30, 90, 110], [0, 1, 1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
	return (
		<div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', opacity: a }}>
			<div style={{ background: 'linear-gradient(90deg, rgba(0,0,0,0), rgba(20,12,8,0.85) 20%, rgba(20,12,8,0.85) 80%, rgba(0,0,0,0))',
				padding: '22px 140px', textAlign: 'center' }}>
				<div style={{ fontFamily: 'Cinzel', fontSize: 30, color: '#e8d6a0' }}>Chapitre {ch.id}</div>
				<div style={{ fontFamily: 'Cinzel', fontWeight: 700, fontSize: 58, color: '#f6dc8a', textShadow: '0 3px 0 #6a4020' }}>{ch.title}</div>
			</div>
		</div>
	);
};

export const Chapter = ({ id }) => {
	const ch = CHAPTERS.find((c) => c.id === id) || CHAPTERS[0];
	return (
		<AbsoluteFill style={{ background: '#000' }}>
			<style>{FONT}</style>
			<Audio src={staticFile(ch.music)} volume={(f) => interpolate(f, [0, 20, 270, 300], [0, 1, 1, 0], { extrapolateRight: 'clamp' })} />
			<Scene name={ch.scene} dur={300} captions={ch.lines} title={false} />
			<ChapterCard ch={ch} />
		</AbsoluteFill>
	);
};

// Portrait du conseiller (Campagne) : vieux lutin sage, barbe blanche, robe violette, bâton.
export const Advisor = () => (
	<AbsoluteFill style={{ background: 'radial-gradient(circle at 50% 40%, #f6e6c0, #c8a46a)' }}>
		<svg width={512} height={512} viewBox="0 0 512 512">
			<circle cx={256} cy={256} r={240} fill="none" stroke="#6a4020" strokeWidth={10} />
			<Lutin x={270} y={470} s={3.6} t={0.3} tunic="#5a3a7a" hat="#3a2a5a" beard pose="staff" />
		</svg>
	</AbsoluteFill>
);

export const RemotionRoot = () => (
	<>
		<Composition id="Conseiller" component={Advisor} durationInFrames={1} fps={30} width={512} height={512} />
		<Composition id="Intro" component={Intro} durationInFrames={INTRO_FRAMES} fps={30} width={W} height={H} />
		{CHAPTERS.map((c) => (
			<Composition key={c.id} id={`Chapitre-${c.id}`} component={Chapter} durationInFrames={300} fps={30}
				width={W} height={H} defaultProps={{ id: c.id }} />
		))}
	</>
);
