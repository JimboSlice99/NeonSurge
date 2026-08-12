--!strict

export type PlotSave = {
	seedId: string?,
	plantedAt: number,
}

export type PlayerData = {
	coins: number,
	ownedSeeds: { [string]: number },
	ownedTools: { [string]: boolean },
	equippedTool: string,
	unlockedZones: { [string]: boolean },
	plots: { [string]: PlotSave },
	ownedPasses: { [string]: boolean },
	rebirths: number,
	lastDailyDay: number,
	tutorialDone: boolean,
	stats: {
		planted: number,
		harvested: number,
		earned: number,
	},
}

export type PlotRuntime = {
	id: string,
	zoneId: string,
	model: Model,
	base: BasePart,
	seedId: string?,
	plantedAt: number,
	readyAt: number,
}

export type HudPayload = {
	coins: number,
	ownedSeeds: { [string]: number },
	ownedTools: { [string]: boolean },
	unlockedZones: { [string]: boolean },
	equippedTool: string,
	selectedSeed: string,
	ownedPasses: { [string]: boolean },
	rebirths: number,
	rebirthCost: number,
	coinMult: number,
	goalText: string,
	dailyReady: boolean,
	dailyAmount: number,
	tutorialDone: boolean,
	stats: {
		planted: number,
		harvested: number,
		earned: number,
	},
}

export type HarvestFxPayload = {
	plotId: string,
	amount: number,
	position: Vector3,
	color: Color3,
	sound: string?,
}

return {}
