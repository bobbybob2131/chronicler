--!strict
-- Author(s): bobbybob2131
-- Last edited: 1 April 2022
-- Description: Runtime equivalent of ChangeHistoryService, with some extra features.

--[[
constructor chronicler.new(object: any, captureProperties: {string | number}, undoStackSize: number?, redoStackSize: number?): Chronicler 
	Create a new chronicler object, `captureProperties` is an array of properties to capture in waypoints

method Chronicler:SetWaypoint() Save the current state of the object as a waypoint
method Chronicler:Undo() Undo most recent action
method Chronicler:Redo() Redo the last action that was undone
method Chronicler:ResetWaypoints() Clears history, removing all undo/redo waypoints
method Chronicler:GetCanUndo(): boolean | waypoint Get last undo-able action, if it exists
method Chronicler:GetCanRedo(): boolean | waypoint Get last redo-able action, if it exists
method Chronicler:SetEnabled(state: boolean?) Set whether or not this chronicler object is enabled
method Chronicler:OverrideStacks(undoStack: waypointStack?, redoStack: waypointStack?) Set the stacks, to flip between saved states
method Chronicler:Destroy() Permanently delete a chronicler object

RBXScriptSignal chroniclerObject.OnUndo Fired when a waypoint is undone
RBXScriptSignal chroniclerObject.OnRedo Fired when a waypoint is redone
]]
local chronicler = {}
local signal = {}

local DEBUG: boolean = true

local output: (...) -> ()
if DEBUG then
	output = function(...)
		print("[Chronicler]", ...)
	end
else
	output = function() end
end

-- Create a new stripped down signal object
function signal.new(): Signal
	local signalObject = {
		_bindable = Instance.new("BindableEvent")
	}

	-- Call the function when the event is raised
	function signalObject:Connect(func)
		self._bindable:Connect(func)
	end

	-- Yield current thread until the event is raised
	function signalObject:Wait()
		self._bindable:Wait()
	end

	return signalObject
end

type waypoint = {[string | number]: any}
type waypointStack = {[string]: number | string}
type Signal = typeof(signal.new())

-- Create a new chronicler object
function chronicler.new(object: any, captureProperties: {string | number}, undoStackSize: number?, redoStackSize: number?): Chronicler
	local undoEvent: BindableEvent = Instance.new("BindableEvent")
	local chroniclerObject: Chronicler = {
		object = object,
		captureProperties = captureProperties,
		undoStack = table.create(undoStackSize or 30),
		redoStack = table.create(redoStackSize or 10),
		enabled = true,
	}
	
	chroniclerObject.OnUndo = signal.new()
	chroniclerObject.OnRedo = signal.new()
	
	-- Save the current state of the object as a waypoint
	function chroniclerObject:SetWaypoint()
		if not self.enabled then return end
		
		local data: waypoint = {}
		for index: number, property: string | number in ipairs(self.captureProperties) do
			local value: any = self.object[property]
			if value then
				data[property] = value
			end
		end
		table.insert(self.undoStack, data)
		
		if #self.redoStack > 0 then
			self.redoStack = {}
		end

		while #self.undoStack > 30 do
			table.remove(self.undoStack, 1)
		end
		output("Set Waypoint:", data)
	end
	
	-- Undo most recent action
	function chroniclerObject:Undo()	
		if #self.undoStack < 1 then	return end

		local waypoint: waypoint = self.undoStack[#self.undoStack - 1]

		if not waypoint then return	end
		
		for property: string | number, value: any in pairs(waypoint) do
			self.object[property] = value
		end
		table.insert(self.redoStack, self.undoStack[#self.undoStack])
		self.undoStack[#self.undoStack] = nil
		
		self.OnUndo._bindable:Fire()
		output("Undo:", waypoint)
	end
	
	-- Redo the last action that was undone
	function chroniclerObject:Redo()
		if #self.redoStack < 0 then	return end

		local waypoint: waypoint = self.redoStack[#self.redoStack]

		if not waypoint then return	end
		
		for property: string | number, value: any in pairs(waypoint) do
			output("redo back to", property, value)
			self.object[property] = value
		end

		table.insert(self.undoStack, waypoint)
		self.redoStack[#self.redoStack] = nil
		
		self.OnRedo._bindable:Fire()
		output("Redo:", waypoint)
	end

	-- Clears history, removing all undo/redo waypoints
	function chroniclerObject:ResetWaypoints()
		table.clear(self.undoStack)
		table.clear(self.redoStack)
		output("Waypoints reset")
	end
	
	-- Get last undo-able action, if it exists
	function chroniclerObject:GetCanUndo(): boolean | waypoint
		local lastPoint: waypoint = self.undoStack[1]
		if not lastPoint then
			output("Cannot undo")
			return false
		else
			output("Can undo")
			return lastPoint
		end
	end
	
	-- Get last redo-able action, if it exists
	function chroniclerObject:GetCanRedo(): boolean | waypoint
		local lastPoint: waypoint = self.undoStack[1]
		if not lastPoint then
			output("Cannot redo")
			return false
		else
			output("Can redo")
			return lastPoint
		end
	end
	
	-- Set whether or not this chronicler object is enabled
	function chroniclerObject:SetEnabled(state: boolean?)
		state = state or not self.enabled
		self.enabled = state
		if state == false then
			self:ResetWaypoints()
		end
		output("Enabled state set to:", state)
	end
	
	-- Set the stacks, to flip between saved states
	function chroniclerObject:OverrideStacks(undoStack: waypointStack?, redoStack: waypointStack?)
		if undoStack then
			self.undoStack = undoStack
		end
		if redoStack then
			self.redoStack = redoStack
		end
		output("Stacks overriden, undo stack:", undoStack, "\nRedo Stack:", redoStack)
	end
	
	-- Permanently delete a chronicler object
	function chroniclerObject:Destroy()
		if self.object.ClassName then -- Object was an Instance of some sort
			self.object:Destroy()
		end
		self.captureProperties = nil
		self.undoStack = nil
		self.redoStack = nil
		self.enabled = nil
		self.OnRedo._bindable:Destroy()
		self.OnUndo._bindable:Destroy()
		output("Destroyed")
	end
	
	return chroniclerObject
end

export type Chronicler = typeof(chronicler.new({"a"}, {1}))

return chronicler
