local sprite = app.activeSprite
local select = {}

for idx, _ in ipairs(sprite.frames) do
	table.insert(select, idx)
end

app.range.frames = select
