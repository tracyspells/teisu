local process = require("@lune/process")

local SPAWN_OPTIONS = {
  shell = true,
} :: process.SpawnOptions

return function(program: string, ...: string)
  local arguments = { ... }
  local result = process.spawn(program, arguments, SPAWN_OPTIONS)

  if not result.ok then
    print(`\n`..result.stdout..`\n`..result.stderr..`\nProcess excited with code `..result.code)
  end

  return result
end
