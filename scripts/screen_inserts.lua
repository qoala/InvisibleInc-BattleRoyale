local inserts =
{
	{
		"hud.lua",
		{ "transitions", },
		{
			name = [[backstab_activate_right]], -- Like activate_left, but expands from the right.
			dx0 = 0.03,
			dy0 = 0,
			dx1 = 0,
			dy1 = 0,
			duration = 0.3,
		},
	},
	{
		"hud.lua",
		{ "widgets", 9, "children", 1, "children" }, -- mainframePnl > daemonPanel >
		{
			name = [[backstabWarning]], -- Copy of hud.lua/warning, but positioned alongside the daemon panel instead of centered.
			isVisible = false,
			noInput = false,
			anchor = 1,
			rotation = 0,
			x = -131 - 175 - 10, -- (-253 [:enemyAbility1.x] + 192 [:EnemyAbility.btn.x] - 70 [:EnemyAbility.btn.w / 2]) - 175 [:self.warningBG.w / 2] - 10 [:spacing]
			xpx = true,
			y = -42, -- -7 [:enemyAbility1.y] + -35 [:EnemyAbility.btn.y]
			ypx = true,
			w = 0,
			h = 0,
			sx = 1,
			sy = 1,
			skin_properties =
			{
				size =
				{
					default =
					{
						w = 0,
						h = 0,
					},
					Small =
					{
						w = 0,
						h = 0,
						hpx = true,
					},
				},
			},
			ctor = [[group]],
			children =
			{
				{
					name = [[warningBG]],
					isVisible = true,
					noInput = false,
					anchor = 1,
					rotation = 0,
					x = 0,
					xpx = true,
					y = 0,
					ypx = true,
					w = 350,
					wpx = true,
					h = 56,
					hpx = true,
					sx = 1,
					sy = 1,
					ctor = [[image]],
					color =
					{
						1,
						1,
						1,
						1,
					},
					images =
					{
						{
							file = [[gui/hud3/hud3-warningbox.png]],
							name = [[]],
						},
					},
				},
				{
					name = [[warningTxtCenter]],
					isVisible = true,
					noInput = true,
					anchor = 1,
					rotation = 0,
					x = 40,
					xpx = true,
					y = 0,
					ypx = true,
					w = 200,
					wpx = true,
					h = 86,
					hpx = true,
					sx = 1,
					sy = 1,
					ctor = [[label]],
					halign = MOAITextBox.CENTER_JUSTIFY,
					valign = MOAITextBox.CENTER_JUSTIFY,
					text_style = [[font1_18_r]],
				},
				{
					name = [[programGroup]],
					isVisible = true,
					noInput = false,
					anchor = 1,
					rotation = 0,
					x = -135,
					xpx = true,
					y = 0,
					ypx = true,
					w = 0,
					h = 0,
					sx = 1,
					sy = 1,
					ctor = [[group]],
					children =
					{
						{
							name = [[programBG]],
							isVisible = true,
							noInput = false,
							anchor = 1,
							rotation = 0,
							x = 0,
							xpx = true,
							y = 0,
							ypx = true,
							w = 128,
							wpx = true,
							h = 64,
							hpx = true,
							sx = 1,
							sy = 1,
							ctor = [[image]],
							color =
							{
								0.192156866192818,
								0.34901961684227,
								0.321568638086319,
								0.843137264251709,
							},
							images =
							{
								{
									file = [[gui/hud3/MainframeIcons_agent_program_bg.png]],
									name = [[]],
									color =
									{
										0.192156866192818,
										0.34901961684227,
										0.321568638086319,
										0.843137264251709,
									},
								},
							},
						},
						{
							name = [[program]],
							isVisible = true,
							noInput = false,
							anchor = 1,
							rotation = 0,
							x = 0,
							xpx = true,
							y = 0,
							ypx = true,
							w = 144,
							wpx = true,
							h = 90,
							hpx = true,
							sx = 0.5,
							sy = 0.5,
							ctor = [[image]],
							color =
							{
								1,
								1,
								1,
								1,
							},
							images =
							{
								{
									file = [[gui/icons/programs_icons/icon-program-fusion.png]],
									name = [[]],
								},
							},
						},
					},
				},
			},
		},
	},
}

return inserts
