local Selection = {}
Selection.CurrentSelection = {}

-- Add items to the current selection
function Selection.AddToSelection(Selected)
	for i, v in ipairs(Selected) do
		if not Selection.IsSelected(v) then
			table.insert(Selection.CurrentSelection, v)
		end
	end
end

-- Remove items from the current selection
function Selection.RemoveFromSelection(Selected)
	for i, v in ipairs(Selected) do
		local index = table.find(Selection.CurrentSelection, v)
		if index then
			table.remove(Selection.CurrentSelection, index)
		end
	end
end

-- Clear the current selection
function Selection.ClearSelection()
	table.clear(Selection.CurrentSelection)
end

-- Check if an item is selected
function Selection.IsSelected(Item)
	return table.find(Selection.CurrentSelection, Item) ~= nil
end

-- Get the current selection count
function Selection.GetSelectionCount()
	return #Selection.CurrentSelection
end

-- Get the current selection as a table
function Selection.GetSelection()
	return Selection.CurrentSelection
end

return Selection