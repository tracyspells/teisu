curl -o scripts/roblox.d.luau https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau

rojo sourcemap dev.project.json -o sourcemap.json

luau-lsp analyze \
	--defs=scripts/roblox.d.luau \
	--defs=test/testez.d.luau \
	--flag:LuauFixIndexerSubtypingOrdering=true \
	--flag:LuauInstantiateInSubtyping=true \
	--sourcemap=sourcemap.json \
	--ignore="**/_Index/**" lib

selene lib
stylua --check lib

rm scripts/roblox.d.luau