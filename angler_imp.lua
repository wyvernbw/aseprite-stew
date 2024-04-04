function zip(...)
	local arrays, ans = { ... }, {}
	local index = 0
	return
		function()
			index = index + 1
			for i, t in ipairs(arrays) do
				if type(t) == 'function' then ans[i] = t() else ans[i] = t[index] end
				if ans[i] == nil then return end
			end
			return table.unpack(ans)
		end
end

function map(tbl, f)
	local t = {}
	for k, v in pairs(tbl) do
		t[k] = f(v)
	end
	return t
end

local function import_animations(data, tag_color, tag_suffix, layers)
	local fs = app.fs
	local angles = { "up", "down", "left", "right" }
	local sprites = {}
	for _, angle in ipairs(angles) do
		local old_sprite = app.activeSprite
		local tag = app.activeSprite:newTag(1, 1)
		tag.name = data.tag_name .. "_" .. angle
		tag.color = tag_color
		local frames = {}
		for i, _ in ipairs(app.activeSprite.layers) do
			local property = "layer_" .. i .. "_import_path"
			local path = data[property]
			if path == nil then
				goto continue
			end
			local dir = fs.filePath(fs.filePath(path))

			local angle_dir = fs.joinPath(dir, angle)
			local files = fs.listFiles(angle_dir)
			table.sort(files)
			local frame_name = files[1]
			local frame_path = fs.joinPath(angle_dir, frame_name)
			print(frame_path)
			local sprite = app.open(frame_path)
			sprites[#sprites + 1] = sprite
			old_sprite.width = math.max(old_sprite.width, sprite.width)
			old_sprite.height = math.max(old_sprite.height, sprite.height)
			frames[i] = sprite.frames
			::continue::
		end
		app.activeSprite = old_sprite
		tag.fromFrame = app.activeSprite.frames[#app.activeSprite.frames]
		for j = 1, #frames[1] do
			local new_frame = app.activeSprite:newEmptyFrame()
			for i = 1, #frames do
				local frame = frames[i][j]
				local current_layer = app.activeSprite.layers[i]
				local source_layer = frame.sprite.layers[1]
				app.activeSprite:newCel(current_layer, frame.frameNumber)
				local cel = source_layer:cel(frame.frameNumber)
				app.activeSprite:newCel(current_layer, new_frame.frameNumber, cel.image, cel.position)
			end
		end
		tag.toFrame = app.activeSprite.frames[#app.activeSprite.frames]
		app.activeSprite:newEmptyFrame()
		tag.toFrame = app.activeSprite.frames[#app.activeSprite.frames - 1]
		--for i, layer in ipairs(app.activeSprite.layers) do
		--	local property = "layer_" .. i .. "_import_path"
		--	local path = data[property]
		--	local dir = fs.filePath(fs.filePath(path))

		--	local angle_dir = fs.joinPath(dir, angle)
		--	local frame_name = fs.listFiles(angle_dir)[1]
		--	local frame_path = fs.joinPath(angle_dir, frame_name)

		--	local sprite = app.open(frame_path)
		--	old_sprite.width = math.max(old_sprite.width, sprite.width)
		--	old_sprite.height = math.max(old_sprite.height, sprite.height)

		--	old_sprite:newEmptyFrame(1)
		--	for _, frame in ipairs(sprite.frames) do
		--		local new_frame = old_sprite:newFrame(frame)
		--		print(i)
		--		old_sprite:newCel(layer, frame.frameNumber)
		--		local cel = sprite.layers[1]:cel(frame.frameNumber)
		--		old_sprite:newCel(layer, new_frame.frameNumber, cel.image, cel.position)
		--		tag.toFrame = new_frame
		--	end
		--end
	end

	-- this doesn't do jack shit
	for _, sprite in ipairs(sprites) do
		sprite:close()
	end
end

local dialogue = Dialog()
local layer_count = 0

dialogue:button {
	id = "new_layer",
	text = "new layer",
	onclick = function()
		layer_count = layer_count + 1
		if layer_count > #app.activeSprite.layers then
			local layer = app.activeSprite:newLayer()
			layer.name = "Layer " .. layer_count
		end
		dialogue:file {
			id = "layer_" .. layer_count .. "_import_path",
			label = "layer " .. layer_count,
			title = "choose a folder",
			open = true,
			save = false,
			filename = "",
			filetypes = "./"
		}
		dialogue:separator()
		dialogue:close()
		dialogue:show {
			autoscrollbars = true,
			hexpand = true
		}
	end
}
dialogue:button { id = "confirm", text = "confirm" }
dialogue:button { id = "cancel", text = "cancel" }
dialogue:entry {
	id = "tag_name",
	label = "tag name"
}
dialogue:color {
	id = "tag_color",
	label = "tag color",
	color = app.Color,
}
dialogue:separator()

local data = dialogue:show { hexpand = true }.data
if data.confirm then
	import_animations(data, data.tag_color, data.tag_suffix, layers)
end
