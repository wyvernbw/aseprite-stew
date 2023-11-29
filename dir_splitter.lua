local dialog = Dialog()
dialog:file {
	id = "save_path",
	label = "save path",
	title = "choose a folder",
	open = true,
	save = false,
	filename = "",
	filetypes = "folder"
}

dialog:button { id = "confirm", text = "confirm" }
dialog:button { id = "cancel", text = "cancel" }

local function removeRightUntil(inputString, c)
	local _, lastIndex = inputString:reverse():find(c)

	if lastIndex then
		return inputString:sub(1, -lastIndex - 1)
	else
		return inputString
	end
end

local function save_files(path)
	local fs = app.fs
	local folder = fs.filePath(path)
	local animations = {}
	for _, tag in ipairs(app.activeSprite.tags) do
		local tag_name = removeRightUntil(tag.name, "_")
		if animations[tag_name] then
			table.insert(animations[tag_name], tag)
		else
			animations[tag_name] = { tag }
		end
	end
	local function toFromFrames(tags)
		local frames = {}
		for _, tag in ipairs(tags) do
			table.insert(frames, tag.fromFrame.frameNumber)
		end
		return frames
	end
	local function toToFrames(tags)
		local frames = {}
		for _, tag in ipairs(tags) do
			table.insert(frames, tag.toFrame.frameNumber)
		end
		return frames
	end
	local sprite = app.activeSprite
	for anim, tags in pairs(animations) do
		print("anim: " .. anim .. "\n")
		print("tags: " .. #tags .. "\n")
		local from_frame = math.min(table.unpack(toFromFrames(tags)))
		local to_frame = math.max(table.unpack(toToFrames(tags)))
		local helper = sprite:newTag(from_frame, to_frame)
		helper.name = anim .. "_helper_tag"
		print("range: " .. from_frame .. " " .. to_frame .. "\n")
		print("helper: " .. helper.name .. "\n")
		local path = fs.joinPath(folder, anim .. ".aseprite")
		app.command.SaveFileCopyAs {
			filename = path,
			ui = false,
			tag = helper.name,
		}
		-- if you don't do this, remove frame tag will remove other tags too
		-- for some reason
		local first_frame = sprite.frames[1]
		helper.fromFrame = first_frame
		helper.toFrame = first_frame
		app.command.RemoveFrameTag(helper)
	end
	app.activeSprite = sprite
end

local data = dialog:show().data
if data.confirm then
	-- import_animations(data.import_path, data.tag_color, data.tag_suffix)
	save_files(data.save_path)
end
