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

local function import_animations(data, tag_color)
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
			print("angle_dir = " .. angle_dir)
			local files = fs.listFiles(angle_dir)
			table.sort(files)
			local frame_name = files[1]
			local frame_path = fs.joinPath(angle_dir, frame_name)
			print("frame_path = " .. frame_path)
			local sprite = app.open(frame_path)
			sprites[#sprites + 1] = sprite
			old_sprite.width = math.max(old_sprite.width, sprite.width)
			old_sprite.height = math.max(old_sprite.height, sprite.height)
			frames[i] = sprite.frames
			::continue::
		end
		app.activeSprite = old_sprite
		tag.fromFrame = app.activeSprite.frames[#app.activeSprite.frames + 1]
		local from_frame_idx = #app.activeSprite.frames
		for j = 1, #frames[1] do
			local new_frame = app.activeSprite:newEmptyFrame()
			for i = 1, #frames do
				local frame = frames[i][j]
				local current_layer = app.activeSprite.layers[i]
				local source_layer = frame.sprite.layers[1]
				local cel = source_layer:cel(frame.frameNumber)
				app.activeSprite:newCel(current_layer, new_frame.frameNumber, cel.image, cel.position)
			end
		end
		tag.toFrame = app.activeSprite.frames[#app.activeSprite.frames + 1]
		app.activeSprite:newEmptyFrame()
		tag.toFrame = app.activeSprite.frames[#app.activeSprite.frames - 1]
		tag.fromFrame = app.activeSprite.frames[from_frame_idx + 1]
	end

	for _, sprite in ipairs(sprites) do
		sprite:close()
	end
end


if not app.params["batch"] then
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
end

local data
if app.params["batch"] then
	print("running in batch mode")
	data = {
		tag_name = app.params["tag_name"],
	}
	local old_layers = {}
	for _, layer in ipairs(app.activeSprite.layers) do
		old_layers[#old_layers + 1] = layer.name
	end
	for i = 0, 99 do
		local layer_path = "layer_" .. i .. "_import_path"
		local layer_name = "layer_" .. i .. "_name"
		if app.params[layer_path] and app.params[layer_name] then
			local layer = app.activeSprite:newLayer()
			data[layer_name] = app.params[layer_name .. "_layer"]
			data[layer_path] = app.params[layer_path]
			layer.name = app.params[layer_name]
			print("new layer: " .. layer.name)
		end
	end
	for _, layer_name in ipairs(old_layers) do
		app.activeSprite:deleteLayer(layer_name)
	end
	import_animations(data, Color { index = #app.activeSprite.palettes[1] / 2 })
	if app.params["batch"] then
		app.command.SaveFile {
			ui = false
		}
	end
else
	print("running in dialogue mode")
	data = dialogue:show { hexpand = true }.data
end

if data.confirm then
	import_animations(data, data.tag_color)
end
