local fs = require("@lune/fs")
local path = require("./path")

local isDir, writeDir, readDir, removeDir = fs.readDir, fs.writeDir, fs.readDir, fs.removeDir
local removeFile, isFile = fs.removeFile, fs.isFile

return function(dir: string)
	if not isDir(dir) then
		return writeDir(dir)
	end

	for _, file in readDir(dir) do
		if isFile(path(dir, file)) then
			removeFile(path(dir, file))
		elseif isDir(path(dir, file)) then
			removeDir(path(dir, file))
		end
	end
end
