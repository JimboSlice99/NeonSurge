--!strict

export type EnemyKind = "Runner" | "Bruiser" | "Boss"

export type GamePhase = "Lobby" | "Countdown" | "Wave" | "Intermission" | "GameOver"

export type PlayerStats = {
	health: number,
	maxHealth: number,
	score: number,
	combo: number,
	kills: number,
	wave: number,
	dashReady: boolean,
}

export type HudSnapshot = {
	phase: GamePhase,
	wave: number,
	score: number,
	combo: number,
	kills: number,
	health: number,
	maxHealth: number,
	enemiesAlive: number,
	countdown: number?,
	message: string?,
}

return {}
