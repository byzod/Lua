-- TFGen: Font Generator for Texter
-- Version 0.3.2

TFGen = {}
TFGen.MAIN_WIDTH  = 611
TFGen.MAIN_HEIGHT = 383
TFGen.ShowSelectRect = false
TFGen.Drawing = {
  X = 0,
	Y = 0,
	W = 0,
	H = 0,
	Modifier  = 0,
	ArrayMode = false,
	SplitMode = false,
	AreaUndo  = false
}
TFGen.UIItems = {
	-- { --example
		-- Type    = "fill",
		-- Pos     = {X=1, Y=1, W=1, H=1}, --X,Y,X2,Y2 for line
		-- Color   = {R=255, G=255, B=255, A=125},
		-- Life    = 555  --  -1:forever X:stop render after X frames
		-- Fadeout = {From=255, T=30}  --  fadeout(alpha) from, duration, "to" is always 0
	-- }
}
TFGen.GlyphCells = {} -- Structure { {X,Y,W,H} }
TFGen.Glyph      = {} -- Structure: {Height, {Mtx, Pos={X, Y, W, H}, Margin={Left, Right, Top}}}  -- Mtx :{ { {ptype, dcolor..}, {}..},{},.. }
TFGen.Cons       = {} -- Controls
function TFGen.Init(register)
	if( register == nil or register == true ) then
		tpt.register_keypress(TFGen._HotkeyHandler)
	end
end

-- Event handlers
function TFGen._HotkeyHandler(key, keyNum, modifier, event)
	if( event==1 ) then -- Modifier record for click event
		if( keyNum == 304 and modifier == 0 ) then TFGen.Drawing.Modifier = 1   end -- shift
		if( keyNum == 306 and modifier == 0 ) then TFGen.Drawing.Modifier = 64  end -- ctrl
		if( keyNum == 308 and modifier == 0 ) then TFGen.Drawing.Modifier = 256 end -- alt
	end
	if( event==2 ) then -- Modifier record for click event
		TFGen.Drawing.Modifier = 0
	end
	if( event==1 and keyNum==116 and modifier==65 ) then -- Ctrl + Shift + t, start
		TFGen.Drawing.X = tpt.mousex
		TFGen.Drawing.Y = tpt.mousey
		TFGen.Drawing.Y = tpt.mousey
		tpt.set_pause(1)
		local notRunning = pcall( tpt.register_step, TFGen._StepHandler )
		pcall( tpt.register_keypress   , TFGen._KeypressHandler)
		pcall( tpt.register_mouseclick , TFGen._ClickHandler   )
		table.insert(
			TFGen.UIItems,
			{
				Type  = "text",
				Text  = "Select an area to place glyph rectangle,\nhold Shift to enter Array Mode when selecting.\nLeft click to place, right click to undo.\nEnter to submit, space to cancel.",
				Pos   = {X=205, Y=190},
				Color = {R=255, G=255, B=25, A=255},
				Life  = 150,
				Fadeout = {From=255, T=60}
			}
		)
		if( notRunning ) then
			table.insert(
				TFGen.UIItems,
				{
					Type  = "text",
					Text  = "Font Generator for Texter is Running...",
					Pos   = {X=425, Y=365},
					Color = {R=255, G=255, B=25, A=155},
					Life  = -1,
				}
			)
		end
	end
end
function TFGen._KeypressHandler(key, keyNum, modifier, event)
	if( event==1 and keyNum==13 and modifier==0 and TFGen.Glyph[1] == nil) then   -- Enter submit glyph choice, do not respose when editing
		pcall(tpt.unregister_mouseclick, TFGen._ClickHandler)
		pcall(tpt.unregister_keypress,   TFGen._KeypressHandler)
		TFGen.ShowSelectRect = false
		TFGen.Glyph = TFGen._GlyphGen(TFGen.GlyphCells)
		TFGen.GlyphCells = {}
		TFGen.Editor.Init()
		TFGen.Editor.Show(true)
	end
	if( event==1 and keyNum==32 and modifier==0 ) then   -- Space cancel all
		TFGen.Reset()
	end
end
function TFGen._ClickHandler(x, y, button, event, scroll) -- button: 0 scroll, 1 left, 2 mid, 4 right; scroll: -1 down, 1 up
	if( event == 3 ) then -- Hold
		if( button == 1 or button == 4 ) then -- Resize rectangle
			TFGen.Drawing.W = x - TFGen.Drawing.X
			TFGen.Drawing.H = y - TFGen.Drawing.Y
			if(x > TFGen.MAIN_WIDTH )then TFGen.Drawing.W = TFGen.MAIN_WIDTH  - TFGen.Drawing.X end
			if(y > TFGen.MAIN_HEIGHT)then TFGen.Drawing.H = TFGen.MAIN_HEIGHT - TFGen.Drawing.Y end
		end
		return false
	end
	if( event == 1 ) then -- Mouse down
		if( button == 1 ) then -- Start draw add rectangle
			if(x > TFGen.MAIN_WIDTH )then x = TFGen.MAIN_WIDTH  end
			if(y > TFGen.MAIN_HEIGHT)then y = TFGen.MAIN_HEIGHT end
			TFGen.Drawing.X = x
			TFGen.Drawing.Y = y
			TFGen.ShowSelectRect = true
			if( TFGen.Drawing.Modifier == 1  ) then -- Shift to active glyph array mode
				TFGen.Drawing.ArrayMode = true
				TFGen.Drawing.Modifier = 0 -- BUG: no key event fire when out of main window
			end
			if( TFGen.Drawing.Modifier == 64 ) then -- Ctrl to active glyph split mode
				TFGen.Drawing.SplitMode = true
				TFGen.Drawing.Modifier = 0 -- BUG: no key event fire when out of main window
			end
		end
		if( button == 4 ) then -- Undo / start area delete
			if( TFGen.Drawing.Modifier == 1 ) then  -- Shift undo all
				local confirmUndoAll = tpt.input("Undo All", "Are you sure to undo all glyph? Type Yes to confirm.", "Yes")
				if( confirmUndoAll == "Yes" ) then
					TFGen.GlyphCells = {}
				end
				TFGen.Drawing.Modifier = 0 -- BUG: no key event fire when out of main window
			elseif( TFGen.Drawing.Modifier == 64 ) then  -- Ctrl to start area undo
				if(x > TFGen.MAIN_WIDTH )then x = TFGen.MAIN_WIDTH  end
				if(y > TFGen.MAIN_HEIGHT)then y = TFGen.MAIN_HEIGHT end
				TFGen.Drawing.X = x
				TFGen.Drawing.Y = y
				TFGen.ShowSelectRect = true
				TFGen.Drawing.AreaUndo = true
			else -- Other, simply undo
				table.remove(TFGen.GlyphCells)
			end
		end
		return false
	end
	if( event == 2 ) then -- Mouse up
		TFGen.ShowSelectRect = false
		if(TFGen.Drawing.W < 0)then
			TFGen.Drawing.W = -1*TFGen.Drawing.W
			TFGen.Drawing.X = TFGen.Drawing.X - TFGen.Drawing.W
		end
		if(TFGen.Drawing.H < 0)then
			TFGen.Drawing.H = -1*TFGen.Drawing.H
			TFGen.Drawing.Y = TFGen.Drawing.Y - TFGen.Drawing.H
		end
		if( button == 1 ) then -- Add rectangle
			if(TFGen.Drawing.W > 0 and TFGen.Drawing.H > 0)then
				if( not (TFGen.Drawing.ArrayMode or TFGen.Drawing.SplitMode) )then -- Normal mode
					table.insert(
						TFGen.GlyphCells,
						{
							X = TFGen.Drawing.X,
							Y = TFGen.Drawing.Y,
							W = TFGen.Drawing.W,
							H = TFGen.Drawing.H
						}
					)
				elseif( TFGen.Drawing.SplitMode ) then -- Split mode
					local glyphGrids = {}
					local baseRect  = {X=0, Y=0, W=1, H=1}
					local grid = {Row=1, Col=1}
					local baseRectStr = tpt.input(
						"Split Mode",
						"1. Base rectangle: You can tweak the (x, y, width, height) of your base box:",
						TFGen.Drawing.X..", "..TFGen.Drawing.Y..", "..TFGen.Drawing.W..", "..TFGen.Drawing.H
					)
					local gridStr = tpt.input("Split Mode", "2. Split: The base box will be split to given (rows, columns)", "2, 4")
					if(baseRectStr ~= nil and gridStr ~= nil) then
						local count = 0
						for arg in string.gmatch(baseRectStr, "%d+") do
							local val = tonumber(arg)
							-- tpt.log("debug: base"..count.." "..val) --debug
							if( val ~= nil and val ~= 0) then 
								if( count == 0 and val <= TFGen.MAIN_WIDTH  )then baseRect.X = val end
								if( count == 1 and val <= TFGen.MAIN_HEIGHT )then baseRect.Y = val end
								if( count == 2 )then
									if(baseRect.X + val <= TFGen.MAIN_WIDTH  )then
										baseRect.W = val
									else
										baseRect.W = TFGen.MAIN_WIDTH  - baseRect.X
									end
								end
								if( count == 3 )then 
									if( baseRect.Y + val <= TFGen.MAIN_HEIGHT )then
										baseRect.H = val
									else
										baseRect.H = TFGen.MAIN_HEIGHT - baseRect.Y
									end
								end
							end
							count = count + 1
							if( count >  3 )then break end
						end
						count = 0
						for arg in string.gmatch(gridStr, "%d+") do
							local val = tonumber(arg)
							-- tpt.log("debug: array"..count.." "..val) --debug
							if( val ~= nil and val ~= 0) then 
								if( count == 0 )then grid.Row = val end
								if( count == 1 )then grid.Col = val end
							end
							count = count + 1
							if( count >  1 )then break end
						end
						TFGen.Drawing.X = baseRect.X
						TFGen.Drawing.Y = baseRect.Y
						TFGen.Drawing.W = baseRect.W / grid.Col
						TFGen.Drawing.H = baseRect.H / grid.Row
						local realH = math.floor(TFGen.Drawing.H)
						for i = 1, grid.Row do
							TFGen.Drawing.X = baseRect.X
							for j = 1, grid.Col do
								table.insert(
									TFGen.GlyphCells,
									{
										X = math.floor(TFGen.Drawing.X),
										Y = math.floor(TFGen.Drawing.Y),
										W = TFGen.Drawing.W,
										H = realH
									}
								)
								TFGen.Drawing.X = TFGen.Drawing.X + TFGen.Drawing.W
							end
							TFGen.Drawing.Y = TFGen.Drawing.Y + TFGen.Drawing.H
						end
					end
				elseif( TFGen.Drawing.ArrayMode ) then -- Array mode
					-- Edit base box
					local baseRect  = {X=0, Y=0, W=1, H=1}
					local arraySize = {Row=1, Col=1}
					local baseRectStr = tpt.input(
						"Array Mode",
						"1. Base rectangle: You can tweak the (x, y, width, height) of your base box:",
						TFGen.Drawing.X..", "..TFGen.Drawing.Y..", "..TFGen.Drawing.W..", "..TFGen.Drawing.H
					)
					local arraySizeStr = tpt.input("Array Mode", "2. Array: The base box will be arrayed with given (rows, columns)", "2, 4")
					if(baseRectStr ~= nil and arraySizeStr ~= nil) then
						local count = 0
						for arg in string.gmatch(baseRectStr, "%d+") do
							local val = tonumber(arg)
							-- tpt.log("debug: base"..count.." "..val) --debug
							if( val ~= nil and val ~= 0) then 
								if( count == 0 and val <= TFGen.MAIN_WIDTH  )then baseRect.X = val end
								if( count == 1 and val <= TFGen.MAIN_HEIGHT )then baseRect.Y = val end
								if( count == 2 )then
									if(baseRect.X + val <= TFGen.MAIN_WIDTH  )then
										baseRect.W = val
									else
										baseRect.W = TFGen.MAIN_WIDTH  - baseRect.X
									end
								end
								if( count == 3 )then 
									if( baseRect.Y + val <= TFGen.MAIN_HEIGHT )then
										baseRect.H = val
									else
										baseRect.H = TFGen.MAIN_HEIGHT - baseRect.Y
									end
								end
							end
							count = count + 1
							if( count >  3 )then break end
						end
						count = 0
						for arg in string.gmatch(arraySizeStr, "%d+") do
							local val = tonumber(arg)
							-- tpt.log("debug: array"..count.." "..val) --debug
							if( val ~= nil and val ~= 0) then 
								if( count == 0 )then arraySize.Row = val end
								if( count == 1 )then arraySize.Col = val end
							end
							count = count + 1
							if( count >  1 )then break end
						end
						TFGen.Drawing.X = baseRect.X
						TFGen.Drawing.Y = baseRect.Y
						TFGen.Drawing.W = baseRect.W
						TFGen.Drawing.H = baseRect.H
						for i = 1, arraySize.Row do
							TFGen.Drawing.X = baseRect.X
							for j = 1, arraySize.Col do
								table.insert(
									TFGen.GlyphCells,
									{
										X = TFGen.Drawing.X,
										Y = TFGen.Drawing.Y,
										W = TFGen.Drawing.W,
										H = TFGen.Drawing.H
									}
								)
								if( TFGen.Drawing.X + 2*TFGen.Drawing.W <= TFGen.MAIN_WIDTH ) then
									TFGen.Drawing.X = TFGen.Drawing.X + TFGen.Drawing.W
								else
									break
								end
							end
							if( TFGen.Drawing.Y + 2*TFGen.Drawing.H <= TFGen.MAIN_HEIGHT ) then
								TFGen.Drawing.Y = TFGen.Drawing.Y + TFGen.Drawing.H
							else
								break
							end
						end
					end
				end
			end
			TFGen.Drawing.ArrayMode = false
			TFGen.Drawing.SplitMode = false
		end
		if( button == 4 ) then -- Perform area delete
			if(TFGen.Drawing.W > 0 and TFGen.Drawing.H > 0 and TFGen.Drawing.AreaUndo == true)then
				local glyphCell = {}
				local index = 1 -- Lua fool
				for i = 1, #TFGen.GlyphCells do -- Delete all glyph inside selection
					glyphCell = TFGen.GlyphCells[index]
					if( glyphCell ~= nil
						and glyphCell.X > TFGen.Drawing.X
						and glyphCell.Y > TFGen.Drawing.Y
						and glyphCell.X + glyphCell.W < TFGen.Drawing.X + TFGen.Drawing.W
						and glyphCell.Y + glyphCell.H < TFGen.Drawing.Y + TFGen.Drawing.H
					) then
						table.remove(TFGen.GlyphCells, index)
					else
						index = index + 1
					end
				end
			end
			TFGen.Drawing.AreaUndo = false
		end
		return false
	end
end
function TFGen._StepHandler()
	TFGen._DrawSelectRect(TFGen.Drawing.X, TFGen.Drawing.Y, TFGen.Drawing.W, TFGen.Drawing.H)
	TFGen._DrawGUI()
end
function TFGen._DrawGUI()
	for i, glyph in ipairs(TFGen.GlyphCells) do
		tpt.drawrect(glyph.X, glyph.Y, glyph.W, glyph.H, 255, 255, 255, 125)
	end
	for i, glyph in ipairs(TFGen.Glyph) do
		if(type(glyph) == "table") then
			local m = {}  -- Short for margin
			local color = {}
			if( glyph.Margin == nil ) then 
				m.top   = 0
				m.left  = 0
				m.right = 0
			else 
				if( glyph.Margin.Top   == nil ) then m.top   = 0 else m.top   =  glyph.Margin.Top   end
				if( glyph.Margin.Left  == nil ) then m.left  = 0 else m.left  =  glyph.Margin.Left  end
				if( glyph.Margin.Right == nil ) then m.right = 0 else m.right =  glyph.Margin.Right end
			end
			if( i == TFGen.CurrentGlyphIndex )then
				color  = {R=55 , G=255, B=55 , A=120} -- Glyph rectangle color
				tcolor = {R=55 , G=255, B=55 , A=200} -- Texte color
				bcolor = {R=255, G=0  , B=0  , A=120} -- Baseline color
				-- Dark background
				local mcolor = {R=0, G=0, B=0, A=200} -- Mask(background) color
				local maskWidth = 14
				pcall(  -- Top
					tpt.fillrect,
					glyph.Pos.X - m.left - maskWidth,
					glyph.Pos.Y - m.top  - maskWidth,
					glyph.Pos.W + m.left + m.right + 2*maskWidth,
					maskWidth,
					mcolor.R, mcolor.G, mcolor.B, mcolor.A
				)
				pcall(  -- Bottom
					tpt.fillrect,
					glyph.Pos.X - m.left - maskWidth,
					glyph.Pos.Y - m.top  + TFGen.Glyph.Height,
					glyph.Pos.W + m.left + m.right + 2*maskWidth,
					maskWidth,
					mcolor.R, mcolor.G, mcolor.B, mcolor.A
				)
				pcall(  -- Left
					tpt.fillrect,
					glyph.Pos.X - m.left - maskWidth,
					glyph.Pos.Y - m.top - 1,
					maskWidth,
					TFGen.Glyph.Height + 2, -- No matter what glyph.Pos.H is
					mcolor.R, mcolor.G, mcolor.B, mcolor.A
				)
				pcall(  -- Right
					tpt.fillrect,
					glyph.Pos.X + glyph.Pos.W + m.right,
					glyph.Pos.Y - m.top - 1,
					maskWidth,
					TFGen.Glyph.Height + 2, -- No matter what glyph.Pos.H is
					mcolor.R, mcolor.G, mcolor.B, mcolor.A
				)
			else
				color  = {R=55 , G=255, B=55 , A=50 } -- Glyph rectangle color
				tcolor = {R=55 , G=255, B=55 , A=60 } -- Texte color
				bcolor = {R=255, G=0  , B=0  , A=50 } -- Baseline color
			end
			pcall(  -- Room rectangle
				tpt.drawrect,
				glyph.Pos.X - m.left,
				glyph.Pos.Y - m.top ,
				glyph.Pos.W + m.left + m.right,
				TFGen.Glyph.Height, -- No matter what glyph.Pos.H is
				color.R, color.G, color.B, color.A
			)
			pcall(  -- baseline
				tpt.drawline,
				glyph.Pos.X - m.left - glyph.Pos.W/4,
				glyph.Pos.Y - m.top  + TFGen.Glyph.Height, -- No matter what glyph.Pos.H is
				glyph.Pos.X + m.left + m.right + glyph.Pos.W*5/4,
				glyph.Pos.Y - m.top  + TFGen.Glyph.Height, -- No matter what glyph.Pos.H is
				bcolor.R, bcolor.G, bcolor.B, bcolor.A
			)
			local char = glyph.Char
			if( char ~= nil) then
				if( char == " " ) then char = "space" end -- Special
				pcall(  -- Assigned character
					tpt.drawtext,
					glyph.Pos.X - m.left,
					glyph.Pos.Y - m.top - 10, -- Default font height + 3?
					i..":"..char,
					tcolor.R, tcolor.G, tcolor.B, tcolor.A
				)
			end
		end
	end
	for i, item  in ipairs(TFGen.UIItems) do
		--Few types, so if-else-if won't be performance critical
		if item.Pos      == nil then item.Pos     = {X=1, Y=1, X2=1, Y2=1, W=1, H=1} end
		if item.Color    == nil then item.Color   = {R=255, G=255, B=255, A=125} end
		if item.Fadeout  == nil then item.Fadeout = {From = 255, T=0}  end
		if item.Life     == nil then item.Life    = 60 end
		if item.Text     == nil then item.Text    = "" end
		
		if(item.Life > 0 or item.Life == -1) then
			if(item.Life > 0)then item.Life = item.Life - 1 end
			--fadeout, no fadeout for forever ones
			if(item.Life <= item.Fadeout.T and item.Life ~= -1)then
				item.Color.A = item.Fadeout.From * item.Life/item.Fadeout.T
			end
			if(item.Type == "text") then
				tpt.drawtext(item.Pos.X, item.Pos.Y, item.Text, item.Color.R, item.Color.G, item.Color.B, item.Color.A)
			elseif (item.Type == "pixel") then
				tpt.drawpixel(item.Pos.X, item.Pos.Y, item.Color.R, item.Color.G, item.Color.B, item.Color.A)
			elseif (item.Type == "line") then
				tpt.drawline(item.Pos.X, item.Pos.Y, item.Pos.X2, item.Pos.Y2, item.Color.R, item.Color.G, item.Color.B, item.Color.A)
			elseif (item.Type == "rect") then
				tpt.drawrect(item.Pos.X, item.Pos.Y, item.Pos.W, item.Pos.H, item.Color.R, item.Color.G, item.Color.B, item.Color.A)
			elseif (item.Type == "fill" ) then
				tpt.fillrect(item.Pos.X, item.Pos.Y, item.Pos.W, item.Pos.H, item.Color.R, item.Color.G, item.Color.B, item.Color.A)
			end
		else -- You were dead
			table.remove(TFGen.UIItems, i)
			i = i-1 --Lua will shifting down other elements to close the space, so we might jump one item off without this
		end
	end
end
function TFGen._DrawSelectRect(posX, posY, width, height)
	if(width < 0)then
		width = -1*width
		posX = posX - width
	end
	if(height < 0)then
		height = -1*height
		posY = posY - height
	end
	if(TFGen.ShowSelectRect)then
		tpt.drawrect(posX, posY, width, height, 255, 255, 255, 125)
	end
end

-- Generate glyph
function TFGen._GlyphGen(glyphCells)
	local glyphList  = {}
	glyphList.Name   = "font1"
	glyphList.Height = -1
	glyphList.Mode   = 3 -- 0: only shape, +1: ptype, +2: dcolor +4: TODO? life, temp, etc.
	for index, glyph in ipairs(glyphCells) do
		-- Minimum Bound Box detection, using the stupid methods, generally O(n), worst O(n^2)
		local mbb = {}
		local foundTopBound    = false -- First top non-empty flag
		local foundBottomBound = false -- First bottom non-empty flag
		for i = 0, glyph.H - 1 do
			for j = 0, glyph.W - 1 do
				if(tpt.get_property("type", glyph.X + j, glyph.Y + i) ~= 0 and foundTopBound == false)then
					mbb.top    = glyph.Y + i           -- The first top non-empty row
					foundTopBound = true
				end
				if(tpt.get_property("type", glyph.X + j, glyph.Y + glyph.H - i) ~= 0 and foundBottomBound == false)then
					mbb.bottom = glyph.Y + glyph.H - i -- The first bottom non-empty row
					foundBottomBound = true
				end
				if( foundTopBound and foundBottomBound ) then break end
			end
			if( foundTopBound and foundBottomBound ) then break end
		end
		local foundLeftBound  = false -- First left non-empty flag
		local foundRightBound = false -- First right non-empty flag
		for i = 0, glyph.W - 1 do
			for j = 0, glyph.H - 1 do
				if(tpt.get_property("type", glyph.X + i, glyph.Y + j) ~= 0 and foundLeftBound == false)then
					mbb.left  = glyph.X + i           -- The first left non-empty column
					foundLeftBound = true
				end
				if(tpt.get_property("type", glyph.X + glyph.W - i, glyph.Y + j) ~= 0 and foundRightBound == false)then
					mbb.right = glyph.X + glyph.W - i -- The first right non-empty column
					foundRightBound = true
				end
				if( foundLeftBound and foundRightBound ) then break end
			end
			if( foundLeftBound and foundRightBound ) then break end
		end
		
		if(mbb.left ~= nil and mbb.right ~= nil and mbb.top ~= nil and mbb.bottom ~= nil) then
			-- tpt.log("top:"..mbb.top..",left:"..mbb.left..",bottom:"..mbb.bottom..",right:"..mbb.right) -- debug
			local glyphArea = {X=mbb.left, Y=mbb.top, W=(mbb.right - mbb.left)+1, H=(mbb.bottom - mbb.top)+1}
			local mtx       = TFGen._DigitizeArea(glyphArea)
			if( (mbb.bottom - mbb.top) >= glyphList.Height) then
				glyphList.Height = mbb.bottom - mbb.top + 1
			end
			table.insert(
				glyphList,
				{
					Char   = "",
					Mtx    = mtx,
					Pos    = glyphArea,
					Margin = {Top= 0, Left=0, Right=0}
				}
			)
		end
	end
	for index, glyph in ipairs(glyphList) do -- Try to put all glyph on their baseline
		glyph.Margin.Top = glyphList.Height - glyph.Pos.H
	end
	return glyphList
end
-- Digitize selected area
function TFGen._DigitizeArea(area)
	local mtx = {}
	local x1 = area.X
	local x2 = area.X + area.W - 1
	local y1 = area.Y
	local y2 = area.Y + area.H - 1
	
	if(area ~= nil and area.X ~= nil and area.Y ~= nil and area.W ~= nil and area.H ~= nil)then
		for y = y1, y2 do
			local row = {}
			for x = x1, x2 do
				local particle = {ptype=0, dcolor=0}
				local isGetPtypeSucceed, ptype  = pcall(tpt.get_property, "type", x, y)
				if( isGetPtypeSucceed )then
					particle.ptype = ptype
					local isGetDcolorSucceed, dcolor = pcall(tpt.get_property, "dcolour", x, y)
					if( isGetDcolorSucceed )then
						particle.dcolor = dcolor
					end
				end
				table.insert(row, particle)
			end
			table.insert(mtx, row)
		end
	end
	return mtx
end
-- Reset
function TFGen.Reset()
	pcall(tpt.unregister_step,       TFGen._StepHandler)
	pcall(tpt.unregister_keypress,   TFGen._KeypressHandler)
	pcall(tpt.unregister_mouseclick, TFGen._ClickHandler)
	TFGen.ShowSelectRect = false
	TFGen.GlyphCells = {}
	TFGen.Glyph = {}
	TFGen.UIItems = {}
end


-- The glyph editor after font generation
TFGen.Editor = {}
TFGen.Editor.Cons = {} -- Controls bag
TFGen.Editor.Pos  = {X=100, Y=100}
TFGen.Editor.Visable = true
TFGen.CurrentGlyphIndex = -1
function TFGen.Editor.Init()
	-- If no glyph generated, quit
	if(TFGen.Glyph.Height == nil or TFGen.Glyph[1] == nil)then
		TFGen.Reset()
		TFGen.Editor.Reset()
		return false
	end
	tpt.register_keypress(TFGen.Editor._KeypressHandler)
	tpt.register_mouseclick(TFGen.Editor._ClickHandler)
	TFGen.CurrentGlyphIndex = 1
	local controlHeight = 14
	-- Position to show
	local properPos = TFGen.Editor.GetClosePos(TFGen.Glyph[TFGen.CurrentGlyphIndex])
	TFGen.Editor.Pos.X = properPos.X
	TFGen.Editor.Pos.Y = properPos.Y
	local editorX = properPos.X
	local editorY = properPos.Y
	local editorW = 144
	
	local lines = 0    -- 1st line : 0
	local prevBtn      = Button:new( editorX              ,	editorY + controlHeight * lines ,	editorW/2 + 1,	controlHeight * 2 + 1,	"Prev"                       )
	local nextBtn      = Button:new( editorX + editorW/2  ,	editorY + controlHeight * lines ,	editorW/2 + 1,	controlHeight * 2 + 1,	"Next"                       )
	lines = lines + 2  -- 2nd line : 2
	local nameBtn      = Button:new( editorX              ,	editorY + controlHeight * lines ,	editorW   + 1,	controlHeight     + 1,	"Name: "..TFGen.Glyph.Name   )
	lines = lines + 1  -- 3rd line : 3
	local charBtn      = Button:new( editorX              ,	editorY + controlHeight * lines ,	editorW   + 1,	controlHeight     + 1,	"Char: []"                   )
	lines = lines + 1  -- 4th line : 4
	local modeBtn      = Button:new( editorX              ,	editorY + controlHeight * lines ,	editorW   + 1,	controlHeight     + 1,	"Mode: "..TFGen.Glyph.Mode   )
	lines = lines + 1  -- 5th line : 4
	local autoCharBtn  = Button:new( editorX              ,	editorY + controlHeight * lines ,	editorW   + 1,	controlHeight     + 1,	"Auto assign"                )
	lines = lines + 1  -- 6th line : 5
	local heightLabel  = Button:new( editorX              ,	editorY + controlHeight * lines ,	editorW/2 + 1,	controlHeight     + 1,	"Font Height"                )
	local heightDecBtn = Button:new( editorX + editorW*3/6,	editorY + controlHeight * lines ,	editorW/6 + 1,	controlHeight     + 1,	"-"                          )
	local heightBtn    = Button:new( editorX + editorW*4/6,	editorY + controlHeight * lines ,	editorW/6 + 1,	controlHeight     + 1,	tostring(TFGen.Glyph.Height) )
	local heightIncBtn = Button:new( editorX + editorW*5/6,	editorY + controlHeight * lines ,	editorW/6 + 1,	controlHeight     + 1,	"+"                          )
	lines = lines + 1  -- 7th line : 6
	local mTopLabel    = Button:new( editorX              ,	editorY + controlHeight * lines ,	editorW/2 + 1,	controlHeight     + 1,	"Margin Top"                 )
	local mTopDecBtn   = Button:new( editorX + editorW*3/6,	editorY + controlHeight * lines ,	editorW/6 + 1,	controlHeight     + 1,	"-"                          )
	local mTopBtn      = Button:new( editorX + editorW*4/6,	editorY + controlHeight * lines ,	editorW/6 + 1,	controlHeight     + 1,	"0"                          )
	local mTopIncBtn   = Button:new( editorX + editorW*5/6,	editorY + controlHeight * lines ,	editorW/6 + 1,	controlHeight     + 1,	"+"                          )
	lines = lines + 1  -- 8th line : 7
	local mLeftLabel   = Button:new( editorX              ,	editorY + controlHeight * lines ,	editorW/2 + 1,	controlHeight     + 1,	"Margin Left"                )
	local mLeftDecBtn  = Button:new( editorX + editorW*3/6,	editorY + controlHeight * lines ,	editorW/6 + 1,	controlHeight     + 1,	"-"                          )
	local mLeftBtn     = Button:new( editorX + editorW*4/6,	editorY + controlHeight * lines ,	editorW/6 + 1,	controlHeight     + 1,	"0"                          )
	local mLeftIncBtn  = Button:new( editorX + editorW*5/6,	editorY + controlHeight * lines ,	editorW/6 + 1,	controlHeight     + 1,	"+"                          )
	lines = lines + 1  -- 9th line : 8
	local mRightLabel  = Button:new( editorX              ,	editorY + controlHeight * lines ,	editorW/2 + 1,	controlHeight     + 1,	"Margin Right"               )
	local mRightDecBtn = Button:new( editorX + editorW*3/6,	editorY + controlHeight * lines ,	editorW/6 + 1,	controlHeight     + 1,	"-"                          )
	local mRightBtn    = Button:new( editorX + editorW*4/6,	editorY + controlHeight * lines ,	editorW/6 + 1,	controlHeight     + 1,	"0"                          )
	local mRightIncBtn = Button:new( editorX + editorW*5/6,	editorY + controlHeight * lines ,	editorW/6 + 1,	controlHeight     + 1,	"+"                          )
	lines = lines + 1  -- 10th line : 9
	local deleteBtn    = Button:new( editorX              ,	editorY + controlHeight * lines ,	editorW   + 1,	controlHeight     + 1,	"Delete this glyph (No undo)")
	lines = lines + 1  -- 11th line : 10
	local cancelAllBtn = Button:new( editorX              ,	editorY + controlHeight * lines ,	editorW/2 + 1,	controlHeight * 2 + 1,	"Cancel All"                 )
	local submitAllBtn = Button:new( editorX + editorW/2  ,	editorY + controlHeight * lines ,	editorW/2 + 1,	controlHeight * 2 + 1,	"Submit All"                 )
	
	prevBtn     :action ( function(sender) TFGen.Editor.CommandHandler("Prev"      ,	sender) end )
	nextBtn     :action ( function(sender) TFGen.Editor.CommandHandler("Next"      ,	sender) end )
	nameBtn     :action ( function(sender) TFGen.Editor.CommandHandler("Name"      ,	sender) end )
	charBtn     :action ( function(sender) TFGen.Editor.CommandHandler("Char"      ,	sender) end )
	modeBtn     :action ( function(sender) TFGen.Editor.CommandHandler("Mode"      ,	sender) end )
	autoCharBtn :action ( function(sender) TFGen.Editor.CommandHandler("AutoAssign",	sender) end )
	heightDecBtn:action ( function(sender) TFGen.Editor.CommandHandler("HeightMod" ,	sender) end )
	heightBtn   :action ( function(sender) TFGen.Editor.CommandHandler("HeightMod" ,	sender) end )
	heightIncBtn:action ( function(sender) TFGen.Editor.CommandHandler("HeightMod" ,	sender) end )
	mTopDecBtn  :action ( function(sender) TFGen.Editor.CommandHandler("MarginMod" ,	sender) end )
	mTopBtn     :action ( function(sender) TFGen.Editor.CommandHandler("MarginMod" ,	sender) end )
	mTopIncBtn  :action ( function(sender) TFGen.Editor.CommandHandler("MarginMod" ,	sender) end )
	mLeftDecBtn :action ( function(sender) TFGen.Editor.CommandHandler("MarginMod" ,	sender) end )
	mLeftBtn    :action ( function(sender) TFGen.Editor.CommandHandler("MarginMod" ,	sender) end )
	mLeftIncBtn :action ( function(sender) TFGen.Editor.CommandHandler("MarginMod" ,	sender) end )
	mRightDecBtn:action ( function(sender) TFGen.Editor.CommandHandler("MarginMod" ,	sender) end )
	mRightBtn   :action ( function(sender) TFGen.Editor.CommandHandler("MarginMod" ,	sender) end )
	mRightIncBtn:action ( function(sender) TFGen.Editor.CommandHandler("MarginMod" ,	sender) end )
	deleteBtn   :action ( function(sender) TFGen.Editor.CommandHandler("Delete"    ,	sender) end )
	cancelAllBtn:action ( function(sender) TFGen.Editor.CommandHandler("CancelAll" ,	sender) end )
	submitAllBtn:action ( function(sender) TFGen.Editor.CommandHandler("SubmitAll" ,	sender) end )
	
	TFGen.Editor.Cons.prevBtn      = prevBtn
	TFGen.Editor.Cons.nextBtn      = nextBtn
	TFGen.Editor.Cons.nameBtn      = nameBtn
	TFGen.Editor.Cons.charBtn      = charBtn
	TFGen.Editor.Cons.modeBtn      = modeBtn
	TFGen.Editor.Cons.autoCharBtn  = autoCharBtn
	TFGen.Editor.Cons.heightLabel  = heightLabel
	TFGen.Editor.Cons.heightDecBtn = heightDecBtn
	TFGen.Editor.Cons.heightBtn    = heightBtn
	TFGen.Editor.Cons.heightIncBtn = heightIncBtn
	TFGen.Editor.Cons.mTopLabel    = mTopLabel
	TFGen.Editor.Cons.mTopDecBtn   = mTopDecBtn
	TFGen.Editor.Cons.mTopBtn      = mTopBtn
	TFGen.Editor.Cons.mTopIncBtn   = mTopIncBtn
	TFGen.Editor.Cons.mLeftLabel   = mLeftLabel
	TFGen.Editor.Cons.mLeftDecBtn  = mLeftDecBtn
	TFGen.Editor.Cons.mLeftBtn     = mLeftBtn
	TFGen.Editor.Cons.mLeftIncBtn  = mLeftIncBtn
	TFGen.Editor.Cons.mRightLabel  = mRightLabel
	TFGen.Editor.Cons.mRightDecBtn = mRightDecBtn
	TFGen.Editor.Cons.mRightBtn    = mRightBtn
	TFGen.Editor.Cons.mRightIncBtn = mRightIncBtn
	TFGen.Editor.Cons.cancelAllBtn = cancelAllBtn
	TFGen.Editor.Cons.submitAllBtn = submitAllBtn
	TFGen.Editor.Cons.deleteBtn    = deleteBtn
	
	interface.addComponent(heightLabel )
	interface.addComponent(mTopLabel   )
	interface.addComponent(mLeftLabel  )
	interface.addComponent(mRightLabel )
	
	interface.addComponent(prevBtn     )
	interface.addComponent(nextBtn     )
	interface.addComponent(nameBtn     )
	interface.addComponent(charBtn     )
	interface.addComponent(modeBtn     )
	interface.addComponent(autoCharBtn )
	interface.addComponent(heightDecBtn)
	interface.addComponent(heightBtn   )
	interface.addComponent(heightIncBtn)
	interface.addComponent(mTopDecBtn  )
	interface.addComponent(mTopBtn     )
	interface.addComponent(mTopIncBtn  )
	interface.addComponent(mLeftDecBtn )
	interface.addComponent(mLeftBtn    )
	interface.addComponent(mLeftIncBtn )
	interface.addComponent(mRightDecBtn)
	interface.addComponent(mRightBtn   )
	interface.addComponent(mRightIncBtn)
	interface.addComponent(deleteBtn   )
	interface.addComponent(cancelAllBtn)
	interface.addComponent(submitAllBtn)
end

-- Command handler
function TFGen.Editor.CommandHandler(command, sender)
	local success, errorMessage = pcall(TFGen.Editor.Commands[command], sender)
	if(success == false) then
		tpt.log("TFGen: Error in command \""..command.."\": "..errorMessage)
	end
end
-- Commands
TFGen.Editor.Commands = {}
function TFGen.Editor.Commands.CancelAll()
	TFGen.Reset()
	TFGen.Editor.Reset()
end
function TFGen.Editor.Commands.SubmitAll()
	if( TFGen.Glyph ~= nil ) then
		TFGen.Editor.SaveFontToFile(TFGen.Glyph)
	else
		tpt.message_box("Font not saved", "No glyph found, no font saved, human.")
	end
	TFGen.Reset()
	TFGen.Editor.Reset()
end
function TFGen.Editor.Commands.Prev(step)
	TFGen.Editor.ChangeIndex(-step)
	TFGen.Editor.MoveTo( TFGen.Editor.GetClosePos( TFGen.Glyph[TFGen.CurrentGlyphIndex] ) )
end
function TFGen.Editor.Commands.Next(step)
	TFGen.Editor.ChangeIndex(step)
	TFGen.Editor.MoveTo( TFGen.Editor.GetClosePos( TFGen.Glyph[TFGen.CurrentGlyphIndex] ) )
end
function TFGen.Editor.Commands.Name(sender)
	local input = tpt.input("Font name", "Set the name for your font", TFGen.Glyph.Name)
	if(string.len(input)>0)then
		input = string.gsub(input, "[^%l%u%d_]*", "")
		input = string.gsub(input, "^%d+", "")
		TFGen.Glyph.Name = input
		sender:text("Name: "..TFGen.Glyph.Name)
	end
end
function TFGen.Editor.Commands.Char(sender)
	local currentGlyph = TFGen.Glyph[TFGen.CurrentGlyphIndex]
	local input = tpt.input("Assign the character", "Assign the character for this glyph")
	if(string.len(input)>0)then
		currentGlyph.Char = string.sub(input, 1, 1)
		sender:text("Char: [ "..currentGlyph.Char.." ]")
	else
		currentGlyph.Char = ""
		sender:text("Char: []")
	end
end
function TFGen.Editor.Commands.Mode(sender)
	local mode = tpt.input("Font file mode", "Information saved to font:\n0  only save shape.\n+1: and ptype.\n+2: and dcolor.\nAdd your choices up then type in.")
	mode = tonumber(mode)
	if( mode~= nil and mode >= 0 )then
		TFGen.Glyph.Mode = mode
		sender:text("Mode: "..TFGen.Glyph.Mode)
	end
end
-- Auto assign characters from current index with given sequence: 
-- 0~9, A~Z, a~z, *space*`-=[]\;',./~!@#$%^&*()_+{}|:"<>? (all symbols then shift-symbols)
function TFGen.Editor.Commands.AutoAssign() 
	local input = tpt.input("Auto assign", "Auto assign characters from current glyph in order: 0~9, A~Z, a~z, space`-=[]\\;',./~!@#$%^&*()_+{}|:\"<>? (the keyboard order)\n0  Clear assigned ones.\n+1 0~9 only\n+2 Upper characters only.\n+4 Lower characters only.\n+8 Symbols only.\nAdd your choices up then type in.", "15", "Any input out of 0~15 will be ignored")
	input = tonumber(input)
	if( input ~= nil and input >= 0 ) then
		-- Auto assign in sequence
		local index        = TFGen.CurrentGlyphIndex
		local glyphCount   = #TFGen.Glyph
		-- Clear assigned ones
		if( bit.bor(input, 0) == 0 ) then
			for i = index, glyphCount do
				if( TFGen.Glyph[index] ~= nil ) then
					TFGen.Glyph[index].Char = ""
					index = index + 1
				end
			end
		else
			-- 0~9
			if( bit.band(input, 1) == 1 ) then
				for i = 0, 9 do
					if( TFGen.Glyph[index] ~= nil and index <= glyphCount ) then
						TFGen.Glyph[index].Char = string.char( 48 + i )
						index = index + 1
					else
						break
					end
				end
			end
			-- Upper chars
			if( bit.band(input, 2) == 2 ) then
				for i = 0, 25 do
					if( TFGen.Glyph[index] ~= nil and index <= glyphCount ) then
						TFGen.Glyph[index].Char = string.char( 65 + i )
						index = index + 1
					else
						break
					end
				end
			end
			-- Lower chars
			if( bit.band(input, 4) == 4 ) then
				for i = 0, 25 do
					if( TFGen.Glyph[index] ~= nil and index <= glyphCount ) then
						TFGen.Glyph[index].Char = string.char( 97 + i )
						index = index + 1
					else
						break
					end
				end
			end
			-- Symbols, ordered in logic sequence to deliver better experience for font creators
			if( bit.band(input, 8) == 8) then
				local symbolMap = {" ", "`", "-", "=", "[", "]", "\\", ";", "'", ",", ".", "/", "~", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "_", "+", "{", "}", "|", ":", "\"", "<", ">", "?"}
				for i = 1, 33 do -- All symbols count: 1 + 32 
					if( TFGen.Glyph[index] ~= nil and index <= glyphCount ) then
						TFGen.Glyph[index].Char = symbolMap[ i ]
						index = index + 1
					else
						break
					end
				end
			end
			-- Clear the rest
			-- if( index < glyphCount ) then
				-- for i = index, glyphCount do
					-- TFGen.Glyph[index].Char = ""
					-- index = index + 1
				-- end
			-- end
		end
		TFGen.Editor.UpdateUI() 
	end
end
function TFGen.Editor.Commands.Delete()
	table.remove(TFGen.Glyph, TFGen.CurrentGlyphIndex)
	if(#TFGen.Glyph < 1) then -- No one left
		TFGen.Reset()
		TFGen.Editor.Reset()
	elseif(TFGen.Glyph[TFGen.CurrentGlyphIndex] == nil) then -- We just kill the last one
		TFGen.Editor.ChangeIndex(-1)
		TFGen.Editor.MoveTo( TFGen.Editor.GetClosePos( TFGen.Glyph[TFGen.CurrentGlyphIndex] ) )
	end
end
function TFGen.Editor.Commands.HeightMod(sender)
	local opt = sender:text()
	local optList = { ["+"]=1, ["-"]=-1 }
	if(opt == "+" or opt == "-")then -- Increase/Decrease btn
		TFGen.Glyph.Height = TFGen.Glyph.Height + optList[opt]
		TFGen.Editor.Cons.heightBtn:text(tostring(TFGen.Glyph.Height))
	else --Height box
		local input = tpt.input("Set font height", "Set the font height for all glyph (1~"..TFGen.MAIN_HEIGHT..")", tostring(TFGen.Glyph.Height))
		if(string.len(input)>0)then
			local h = tonumber(input)
			if(h ~= nil and h > 0 and h <= TFGen.MAIN_HEIGHT)then
				TFGen.Glyph.Height = h
				sender:text(tostring(TFGen.Glyph.Height))
			end
		end
	end
end
function TFGen.Editor.Commands.MarginMod(sender)
	local opt = sender:text()
	local optList = { ["+"]=1, ["-"]=-1 }
	local currentGlyphMargin = TFGen.Glyph[TFGen.CurrentGlyphIndex].Margin
	local marginType = ""
	local maxVal = 0
	if(     sender == TFGen.Editor.Cons.mTopDecBtn   or sender == TFGen.Editor.Cons.mTopIncBtn   or sender == TFGen.Editor.Cons.mTopBtn  )then 
		marginType = "Top"
		maxVal = TFGen.MAIN_HEIGHT - 1
	elseif( sender == TFGen.Editor.Cons.mLeftDecBtn  or sender == TFGen.Editor.Cons.mLeftIncBtn  or sender == TFGen.Editor.Cons.mLeftBtn )then
		marginType = "Left"
		maxVal = TFGen.MAIN_WIDTH - 1
	elseif( sender == TFGen.Editor.Cons.mRightDecBtn or sender == TFGen.Editor.Cons.mRightIncBtn or sender == TFGen.Editor.Cons.mRightBtn)then
		marginType = "Right"
		maxVal = TFGen.MAIN_WIDTH - 1
	end
	if(opt == "+" or opt == "-")then -- Increase/Decrease btn
		if( TFGen.Drawing.Modifier == 0 ) then -- None, single operation
			currentGlyphMargin[marginType] = currentGlyphMargin[marginType] + optList[opt]
		elseif( TFGen.Drawing.Modifier == 1 ) then -- Shift, operate all glyph
			for i = 1, #TFGen.Glyph do
				TFGen.Glyph[i].Margin[marginType] = TFGen.Glyph[i].Margin[marginType] + optList[opt]
			end
		end
		-- tpt.log("Modifier is: "..TFGen.Drawing.Modifier)-- debug
		if(marginType == "Top")then
			TFGen.Editor.Cons.mTopBtn     :text(tostring(currentGlyphMargin[marginType]))
		elseif(marginType == "Left")then
			TFGen.Editor.Cons.mLeftBtn    :text(tostring(currentGlyphMargin[marginType]))
		elseif(marginType == "Right")then
			TFGen.Editor.Cons.mRightBtn   :text(tostring(currentGlyphMargin[marginType]))
		end
	else --Value box
		local inputTitle = ""
		local inputHead  = ""
		if( TFGen.Drawing.Modifier == 0 ) then -- None, single operation
			inputTitle = "Set Margin "
			inputHead  = "Set the Margin "
		elseif( TFGen.Drawing.Modifier == 1 ) then -- Shift, operate all glyph
			inputTitle = "Set All Glyph's Margin "
			inputHead  = "Set all glyph's Margin "
		end
		local input = tpt.input(inputTitle..marginType, inputHead..marginType.." value ("..-maxVal.."~"..maxVal..")")
		if(string.len(input)>0)then
			local val = tonumber(input)
			if(val ~= nil and math.abs(val) <= maxVal)then
				if( TFGen.Drawing.Modifier == 0 ) then -- None, single operation
					currentGlyphMargin[marginType] = val
				elseif( TFGen.Drawing.Modifier == 1 ) then -- Shift, operate all glyph
					for i = 1, #TFGen.Glyph do
						TFGen.Glyph[i].Margin[marginType] = val
					end
				end
				sender:text(tostring(currentGlyphMargin[marginType]))
			end
		end
		TFGen.Drawing.Modifier = 0
	end
end

-- Handlers
function TFGen.Editor._KeypressHandler(key, keyNum, modifier, event)
	if(TFGen.Editor.Visable and keyNum ~= 96 and keyNum ~= 122 and keyNum ~= 304 and keyNum ~= 306 and keyNum ~= 308) then -- [~], [z] and modifiers is usable
		return false
	end
end
function TFGen.Editor._ClickHandler(x, y, button, event, scroll) -- button: 0 scroll, 1 left, 2 mid, 4 right; scroll: -1 down, 1 up
	local step = 1
	if( TFGen.Drawing.Modifier == 1 ) then -- Shift for 5
		step = 5
	end
	if( button == 0 and scroll == 1) then  -- Scroll up
		TFGen.Editor.Commands.Prev(step)
		return false
	end
	if( button == 0 and scroll == -1) then -- Scroll down
		TFGen.Editor.Commands.Next(step)
		return false
	end
end

-- Helper methods
function TFGen.Editor.Show(vis)
	if(vis == nil) then return TFGen.Editor.Visable end
	TFGen.Editor.Visable = vis
	for id, control in pairs(TFGen.Editor.Cons) do
		control:visible(vis)
	end
end
function TFGen.Editor.Reset()
	pcall(tpt.unregister_keypress,   TFGen.Editor._KeypressHandler)
	pcall(tpt.unregister_mouseclick, TFGen.Editor._ClickHandler)
	TFGen.Editor.Show(false)
	TFGen.Editor.Cons = {}
	TFGen.CurrentGlyphIndex = -1
end
function TFGen.Editor.GetClosePos(glyph)            -- Get the proper position close to the glyph
	local properPos = {X=0, Y=0}
	local glyphPos  = {
		X  = glyph.Pos.X ,
		Y  = glyph.Pos.Y ,
		X2 = glyph.Pos.X + glyph.Pos.W,
		Y2 = glyph.Pos.Y + glyph.Pos.H
	}
	if(glyphPos.X > TFGen.MAIN_WIDTH/2)then -- On the right side..
		properPos.X = TFGen.MAIN_WIDTH/2 - 154
	elseif(glyphPos.X2 < TFGen.MAIN_WIDTH/2)then -- On the left side..
		properPos.X = TFGen.MAIN_WIDTH/2 + 10
	else -- Center annoying ones, let's see..
		if(math.abs(glyphPos.X - TFGen.MAIN_WIDTH/2) > math.abs(glyphPos.X2 - TFGen.MAIN_WIDTH/2))then --..more to the left..
			properPos.X = glyphPos.X2 + 10
			-- Editor width: 144
			if( properPos.X + 144 > TFGen.MAIN_WIDTH ) then
				properPos.X = TFGen.MAIN_WIDTH - 144
			end
		else --..more to the right
			properPos.X = glyphPos.X - 154
		end
	end
	-- ..and we can not exceed the main bound.
	if( properPos.X < 0                )then properPos.X = 0                end
	if( properPos.X > TFGen.MAIN_WIDTH )then properPos.X = TFGen.MAIN_WIDTH end
	properPos.Y = TFGen.MAIN_HEIGHT/2 - 77 -- lucy number
	return properPos
end
function TFGen.Editor.MoveTo(pos)                   -- Move to (pos.X, pos.Y)
	for id, control in pairs(TFGen.Editor.Cons) do
		local currentX, currentY = control:position()
		local newPos = {
			X = ( pos.X - TFGen.Editor.Pos.X ) + currentX,
			Y = ( pos.Y - TFGen.Editor.Pos.Y ) + currentY
		}
		control:position(newPos.X, newPos.Y)
	end
	TFGen.Editor.Pos = pos
	TFGen.Editor.UpdateUI()
end
function TFGen.Editor.ChangeIndex(step)             -- Positive number to go next, negative number to go back, always loop
	TFGen.CurrentGlyphIndex = ((TFGen.CurrentGlyphIndex - 1) + step) % #TFGen.Glyph + 1
	TFGen.Editor.UpdateUI()
end
function TFGen.Editor.UpdateUI()                    -- Fresh UI
	if( TFGen.CurrentGlyphIndex > 0 and TFGen.CurrentGlyphIndex <= #TFGen.Glyph ) then
		local currentGlyph = TFGen.Glyph[TFGen.CurrentGlyphIndex]
		if( string.len(currentGlyph.Char) > 0 ) then
			TFGen.Editor.Cons.charBtn   :text( "Char: [ "..currentGlyph.Char.." ]" )
		else
			TFGen.Editor.Cons.charBtn   :text( "Char: []" )
		end
		TFGen.Editor.Cons.mTopBtn   :text( tostring(currentGlyph.Margin.Top  ) )
		TFGen.Editor.Cons.mLeftBtn  :text( tostring(currentGlyph.Margin.Left ) )
		TFGen.Editor.Cons.mRightBtn :text( tostring(currentGlyph.Margin.Right) )
	end
end
function TFGen.Editor.SaveFontToFile(glyphList, cachedStr)
	local fontStr = {}
	if( cachedStr ~= nil and string.len(cachedStr) > 0 ) then
		fontStr = cachedStr
	else
		local fontHead = "\n--- Font Generated by TFGen ---\n"
		fontHead = fontHead.."\nif(Texter._Fontmatrix == nil) then Texter._Fontmatrix = {} end"
		fontHead = fontHead.."\nTexter._Fontmatrix[\""..glyphList.Name.."\"] = {"
		table.insert( fontStr, "\n\tHeight = "..glyphList.Height )  -- Height
		local glyphStr = {}
		for i, glyph in ipairs(glyphList) do
			glyphStr = {}
			local char   = "nil"
			local mtx    = {}
			if(string.len(glyph.Char) > 0) then
				char = string.gsub(glyph.Char, "[\\\"]", "\\%1")
			end
			-- Space is no need to save it's matrix, just save the width is ok.
			if( char ~= " " ) then
				-- Generate mtx str ... as long as it's not a space
				for j = 1, #glyph.Mtx do
					for k = 1, #glyph.Mtx[j] do
						local particle = glyph.Mtx[j][k]
						-- Save ptype
						if( (particle.ptype ~= 0) and ((bit.bor(glyphList.Mode, 0) == 0) or (bit.band(glyphList.Mode, 1) ~= 1)) ) then
							particle.ptype = 1
						end
						-- Save dcolor
						if( (particle.ptype == 0) or (bit.bor(glyphList.Mode, 0) == 0) or (bit.band(glyphList.Mode, 2) ~= 2) ) then
							particle.dcolor = 0
						end
						if( particle.dcolor == 0 ) then
							glyph.Mtx[j][k] = particle.ptype
						else
							-- 0xAARRGGBBTT, TT is ptype in Hex, AARRGGBB is dcolor
							glyph.Mtx[j][k] = "0x"..string.format("%X", particle.dcolor)..string.format("%X", particle.ptype)
						end
					end
					table.insert( mtx, "{"..table.concat(glyph.Mtx[j], ",").."}" )
				end
				table.insert( glyphStr, "\n\t\tMtx = {\n\t\t\t"..table.concat(mtx, ",\n\t\t\t").."\n\t\t}" ) -- Matrix
			end
			
			if(glyph.Margin ~= nil and bit.bor(glyph.Margin.Top, glyph.Margin.Left, glyph.Margin.Right) ~= 0)then
				marginStr = {} -- Margin
				if(glyph.Margin.Top   ~= 0)then table.insert( marginStr, "\n\t\t\tTop   = "..glyph.Margin.Top   ) end
				if(glyph.Margin.Left  ~= 0)then table.insert( marginStr, "\n\t\t\tLeft  = "..glyph.Margin.Left  ) end
				if(glyph.Margin.Right ~= 0)then table.insert( marginStr, "\n\t\t\tRight = "..glyph.Margin.Right ) end
				table.insert( glyphStr, "\n\t\tMargin = {"..table.concat(marginStr, ",").."\n\t\t}" )
			end
			table.insert( fontStr, "\n\t[\""..char.."\"] = {"..table.concat(glyphStr, ",").."\n\t}" ) -- Glyph
		end
		fontStr = fontHead..table.concat(fontStr, ",").."\n}"
	end
	local fontFileName = glyphList.Name..".texterfont"
	local file = io.open(fontFileName, "w")
	if file then
		file:write(fontStr)
		file:close()
		local shouldMove = ""
		if( Texter ~= nil and Texter.FONT_FOLDERS_TO_LOAD ~= nil ) then
			shouldMove = tpt.input("File saved", "I can move the font to where it should be, let me try?\nType Yes to continue, anything else to cancel.", "Yes")
		else
			tpt.message_box("File saved", "Font file \""..fontFileName.."\"\nsaved to game dir, please move it to\nthe font folder.")
		end
		if( shouldMove == "Yes" ) then
			TFGen.Editor.MoveFontToFontDir(".", Texter.FONT_FOLDERS_TO_LOAD, fontFileName)
		end
		Texter.Init(false)
	else
		local shouldTryAgain = tpt.input("Unknown Error", "There is an error saving the file, should I try again?\nType Yes to continue, anything else to cancel", "Yes")
		if( shouldTryAgain == "Yes" ) then
			TFGen.Editor.SaveFontToFile(glyph, fontStr) -- Try again
		end
	end
end
function TFGen.Editor.MoveFontToFontDir(rootPath, foldersToLoad, fontFileName)
	local fontFolder = TFGen.Editor.FindDeepestFontFolder(rootPath, foldersToLoad, Texter.FONT_SEARCH_DEPTH)
	local success = false
	if( fontFolder~= nil and string.len(fontFolder) > 0 or foldersToLoad["."] ~= nil ) then -- If . is available, no need to move
		success = fileSystem.move(fontFileName, fontFolder.."\\"..fontFileName)
	end
	if( not success ) then
		tpt.message_box("Move font faild", "Sorry, font file \""..fontFileName.."\"\nfailed to move :(\nPlease move it to \""..fontFolder.."\".")
	end
end
function TFGen.Editor.FindDeepestFontFolder(rootPath, foldersToLoad, depth) -- But not the root folder
	if(  rootPath == nil  ) then
		rootPath = "."
	end
	if(  depth == nil  ) then
		depth = 1
	end
	local fontFolder = nil
	for i, folderName in ipairs(foldersToLoad) do
		if( string.match(rootPath, "\\?"..folderName.."$") ~= nil and rootPath ~= ".") then
			fontFolder = rootPath -- If it's the folder we look for
			break
		end
	end
	-- Let's check the subs for deepest one ( by overwrite fontFolder )
	if(  depth > 0  ) then
		local subs = fs.list(rootPath)
		local subFontFolder = nil
		for i=1, #subs do
			if( Texter._IsFolder(rootPath.."\\"..subs[i]) ) then
				subFontFolder = TFGen.Editor.FindDeepestFontFolder(rootPath.."\\"..subs[i], foldersToLoad, depth - 1)
			end
			if( subFontFolder ~= nil and string.len(subFontFolder) > 0 ) then  -- Cheers!
				fontFolder = subFontFolder
				break
			end
		end
	end
	return fontFolder
end

TFGen.Init()
