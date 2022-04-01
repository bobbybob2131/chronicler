# Chronicler
Runtime equivalent of ChangeHistoryService, with some extra features. Feel free to open a pull request and contribute, but please use the official Luau style guide.

## API
constructor Create a new chronicler object, `captureProperties` is an array of properties to capture in waypoints
```
chronicler.new(object: any, captureProperties: {string | number}, undoStackSize: number?, redoStackSize: number?): Chronicler 
```

method Save the current state of the object as a waypoint
```
Chronicler:SetWaypoint(name: string) 
```
method Undo most recent action
```
Chronicler:Undo()
```
method Redo the last action that was undone
```
Chronicler:Redo()
```
method Clears history, removing all undo/redo waypoints
```
Chronicler:ResetWaypoints()
```
method Get last undo-able action, if it exists
```
Chronicler:GetCanUndo(): boolean | waypoint
```
method Get last redo-able action, if it exists
```
Chronicler:GetCanRedo(): boolean | waypoint
```
method Set whether or not this chronicler object is enabled, toggle if no state is provided
```
Chronicler:SetEnabled(state: boolean?)
```
method Set the stacks, to flip between saved states
```
Chronicler:OverrideStacks(undoStack: waypointStack?, redoStack: waypointStack?)
```
method Permanently delete a chronicler object
```
Chronicler:Destroy()
```
