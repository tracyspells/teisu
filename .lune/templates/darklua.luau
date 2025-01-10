--!nonstrict

return {
	generator = "retain_lines",
	rules = {
		{
			rule = "convert_require",
			target = {
				indexing_style = "property",
				name = "roblox",
				rojo_sourcemap = "./sourcemap.json",
			},
			current = {
				name = "path",
				["module_folder_name"] = "init",
				sources = {},
			},
		},
		{
			identifier = "__DEV__",
			rule = "inject_global_value",
			value = false,
		},
		"remove_empty_do",
		"compute_expression",
		"remove_unused_if_branch",
		"remove_unused_while",
	},
}
