local process = require("@lune/process")

local SPAWN_OPTIONS = {
  shell = true,
} :: process.SpawnOptions

return function(program: string, ...: string)
  local arguments = { ... }
  local result = process.spawn(program, arguments, SPAWN_OPTIONS)

  if not result.ok then
    print(result.stdout..`\n`..result.stderr..`\nProcess exited with code {result.code}`..`\n`)
  end

  return result
end
