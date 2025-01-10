local Enum = game and Enum or require("@mock/").Enum
local Color3 = game and Color3 or require("@mock/").Color3

return table.freeze {
	ScreenGui = table.freeze {
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	},

	BillboardGui = table.freeze {
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Active = true,
	},

	SurfaceGui = table.freeze {
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 50,
	},

	Frame = table.freeze {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
	},

	ScrollingFrame = table.freeze {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		ScrollBarImageColor3 = Color3.new(0, 0, 0),
	},

	TextLabel = table.freeze {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Font = Enum.Font.SourceSans,
		Text = "",
		TextColor3 = Color3.new(0, 0, 0),
		TextSize = 14,
	},

	TextButton = table.freeze {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.SourceSans,
		Text = "",
		TextColor3 = Color3.new(0, 0, 0),
		TextSize = 14,
	},

	TextBox = table.freeze {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = Enum.Font.SourceSans,
		Text = "",
		TextColor3 = Color3.new(0, 0, 0),
		TextSize = 14,
	},

	ImageLabel = table.freeze {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
	},

	ImageButton = table.freeze {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		AutoButtonColor = false,
	},

	ViewportFrame = table.freeze {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
	},

	VideoFrame = table.freeze {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
	},

	CanvasGroup = table.freeze {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
	},

	UIListLayout = table.freeze {
        SortOrder = Enum.SortOrder.LayoutOrder
    },
   
    UIGridLayout = table.freeze {
        SortOrder = Enum.SortOrder.LayoutOrder
    },

    UITableLayout = table.freeze {
        SortOrder = Enum.SortOrder.LayoutOrder
    },

    UIPageLayout = table.freeze {
        SortOrder = Enum.SortOrder.LayoutOrder
    },
}