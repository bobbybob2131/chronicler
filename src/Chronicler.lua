--!strict
-- Author(s): bobbybob2131
-- Last edited: 1 April 2022
-- Description: Runtime equivalent of ChangeHistoryService, with some extra features.

--[[
constructor chronicler.new(object: any, captureProperties: {string | number}, undoStackSize: number?, redoStackSize: number?): chroniclerObject 
	Create a new chronicler object, `captureProperties` is an array of properties to capture in waypoints

method chroniclerObject:SetWaypoint(name: string) Save the current state of the object as a waypoint
method chroniclerObject:Undo() Undo most recent action
method chroniclerObject:Redo() Redo the last action that was undone
method chroniclerObject:ResetWaypoints() Clears history, removing all undo/redo waypoints
method chroniclerObject:GetCanUndo(): boolean | waypoint Get last undo-able action, if it exists
method chroniclerObject:GetCanRedo(): boolean | waypoint Get last redo-able action, if it exists
method chroniclerObject:SetEnabled(state: boolean?) Set whether or not this chronicler object is enabled, toggle if no state is provided
method chroniclerObject:OverrideStacks(undoStack: waypointStack?, redoStack: waypointStack?) Set the stacks, to flip between saved states
method chronicler:Destroy() Permanently delete a chronicler object

RBXScriptSignal chroniclerObject.OnUndo Fired when a waypoint is undone with the name of the point
RBXScriptSignal chroniclerObject.OnRedo Fired when a waypoint is redone with the name of the point
]]
local chronicler = {}
local signal = {}

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
export type Signal = typeof(signal.new())

-- Create a new chronicler object
function chronicler.new(object: any, captureProperties: {string | number}, undoStackSize: number?, redoStackSize: number?): chroniclerObject
	local undoEvent: BindableEvent = Instance.new("BindableEvent")
	local chroniclerObject: chroniclerObject = {
		object = object,
		captureProperties = captureProperties,
		undoStack = table.create(undoStackSize or 30),
		redoStack = table.create(redoStackSize or 10),
		enabled = true,
	}
	
	chroniclerObject.OnUndo = signal.new()
	chroniclerObject.OnRedo = signal.new()
	
	-- Save the current state of the object as a waypoint
	function chroniclerObject:SetWaypoint(name: string)
		if not self.enabled then return end
		
		local data: waypoint = {
			_name = name or "Unnamed Waypoint"
		}
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
	end
	
	-- Undo most recent action
	function chroniclerObject:Undo()	
		if #self.undoStack < 1 then	return end

		local waypoint: waypoint = self.undoStack[#self.undoStack - 1]

		if not waypoint then return	end
		local name: string = waypoint._name
		
		for property: string | number, value: any in pairs(waypoint) do
			self.object[property] = value
		end
		table.insert(self.redoStack, self.undoStack[#self.undoStack])
		self.undoStack[#self.undoStack] = nil
		
		self.OnUndo._bindable:Fire(name)
	end
	
	-- Redo the last action that was undone
	function chroniclerObject:Redo()
		if #self.redoStack < 0 then	return end

		local waypoint: waypoint = self.redoStack[#self.redoStack]

		if not waypoint then return	end
		local name: string = waypoint._name
		
		for property: string | number, value: any in pairs(waypoint) do
			self.object[property] = value
		end

		table.insert(self.undoStack, waypoint)
		self.redoStack[#self.redoStack] = nil
		
		self.OnRedo._bindable:Fire(name)
	end

	-- Clears history, removing all undo/redo waypoints
	function chroniclerObject:ResetWaypoints()
		table.clear(self.undoStack)
		table.clear(self.redoStack)
	end
	
	-- Get last undo-able action, if it exists
	function chroniclerObject:GetCanUndo(): boolean | waypoint
		local lastPoint: waypoint = self.undoStack[1]
		if not lastPoint then
			return false
		else
			return lastPoint
		end
	end
	
	-- Get last redo-able action, if it exists
	function chroniclerObject:GetCanRedo(): boolean | waypoint
		local lastPoint: waypoint = self.undoStack[1]
		if not lastPoint then
			return false
		else
			return lastPoint
		end
	end
	
	-- Set whether or not this chronicler object is enabled, toggle if no state is provided
	function chroniclerObject:SetEnabled(state: boolean?)
		state = state or not self.enabled
		self.enabled = state
		if state == false then
			self:ResetWaypoints()
		end
	end
	
	-- Set the stacks, to flip between saved states
	function chroniclerObject:OverrideStacks(undoStack: waypointStack?, redoStack: waypointStack?)
		if undoStack then
			self.undoStack = undoStack
		end
		if redoStack then
			self.redoStack = redoStack
		end
	end
	
	-- Permanently delete a chronicler object
	function chronicler:Destroy()
		if self.object.ClassName then -- Object was an Instance of some sort
			self.object:Destroy()
		end
		self.captureProperties = nil
		self.undoStack = nil
		self.redoStack = nil
		self.enabled = nil
		self.OnRedo._bindable:Destroy()
		self.OnUndo._bindable:Destroy()
	end
	
	return chroniclerObject
end

export type chroniclerObject = typeof(chronicler.new({"a"}, {1}))

return chronicler
