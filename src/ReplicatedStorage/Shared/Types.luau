--!strict

export type SeedId = string
export type ToolId = string
export type ZoneId = string

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
	stats: {
		planted: number,
		harvested: number,
		earned: number,
	},
}

return {}
