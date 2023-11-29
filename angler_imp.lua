local function import_animations(path, tag_color, tag_suffix)
	local fs = app.fs
	local dir = fs.filePath(fs.filePath(path))
	local anim = fs.fileName(dir)
	local angles = { "up", "down", "left", "right" }

	local old_sprite = app.activeSprite
	for _, angle in ipairs(angles) do
		local angle_dir = fs.joinPath(dir, angle)
		local frame_name = fs.listFiles(angle_dir)[1]
		local frame_path = fs.joinPath(angle_dir, frame_name)
		local tag_name = anim .. "_" .. angle
		if tag_suffix ~= "" then
			tag_name = anim .. "_" .. tag_suffix .. "_" .. angle
		end

		local sprite = app.open(frame_path)
		app.activeSprite = old_sprite
		old_sprite.width = math.max(old_sprite.width, sprite.width)
		old_sprite.height = math.max(old_sprite.height, sprite.height)

		old_sprite:newEmptyFrame(1)
		local tag = old_sprite:newTag(1, 1)
		tag.name = tag_name
		tag.color = tag_color
		for _, frame in ipairs(sprite.frames) do
			local new_frame = old_sprite:newFrame(frame)
			local cel = sprite.layers[1]:cel(frame.frameNumber)
			old_sprite:newCel(old_sprite.layers[1], new_frame.frameNumber, cel.image, cel.position)
			tag.toFrame = new_frame
		end
	end
end

local dialogue = Dialog()
dialogue:file {
	id = "import_path",
	label = "import path",
	title = "choose a folder",
	open = true,
	save = false,
	filename = "",
	filetypes = "./"
}
dialogue:color {
	id = "tag_color",
	label = "tag color",
	color = app.Color,
}
dialogue:entry {
	id = "tag_suffix",
	label = "tag suffix",
	text = ""
}
dialogue:button { id = "confirm", text = "confirm" }
dialogue:button { id = "cancel", text = "cancel" }

local data = dialogue:show().data
if data.confirm then
	import_animations(data.import_path, data.tag_color, data.tag_suffix)
end
