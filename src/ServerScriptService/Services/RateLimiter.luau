--!strict

local RateLimiter = {}

local last: { [Player]: { [string]: number } } = {}

function RateLimiter.Allow(player: Player, key: string, cooldown: number): boolean
	local now = os.clock()
	local bucket = last[player]
	if not bucket then
		bucket = {}
		last[player] = bucket
	end
	local prev = bucket[key]
	if prev and (now - prev) < cooldown then
		return false
	end
	bucket[key] = now
	return true
end

function RateLimiter.Clear(player: Player)
	last[player] = nil
end

return RateLimiter
