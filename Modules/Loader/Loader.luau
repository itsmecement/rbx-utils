--[[
	# Loader made by Cement:
	Roblox: @Tugrul_BlackEagle
	Discord: @itsme.cement

	## Version: 1.0.0

	-# Don't forget to check Settings variable!!

	Example Usage:
	```
		local Loader = require(path.to.Loader)

		local Init = Loader.Load(
			workspace.Folder:GetChildren(),
			"Init",
			true
		)
		print("Init Results:", {
			Loaded = Init.Loaded,
			Failed = Init.Failed,
			Backup = Init.Backup,
		})
		local Start = Loader.Load(Init.Loaded, "Start", true)
		print("Start Results:", {
			Loaded = Start.Loaded,
			Failed = Start.Failed,
			Backup = Start.Backup, -- will be empty because "Init" already excluded backups
		})
	```
]]

--!strict

--// Variables
local Loader = {}
-- you can change here
local Settings = {
	Timeout = 4,
	BackupExtension = ".bak",
}
local dynamicRequire = require :: (ModuleScript) -> any -- to prevent stupid strict's stupid strictness

--// Functions
local function dWarn(message: string)
	warn("[Loader]", message)
end
local function runModuleWithTimeout(timeout: number, fn: () -> ...any): (boolean, any)
	local caller = coroutine.running()
	local completed = false
	local timedOut = false
	local success = false
	local result: any = nil

	local workerThread: thread? = nil
	workerThread = task.spawn(function()
		success, result = pcall(fn)
		completed = true
		if coroutine.status(caller) == "suspended" then
			task.spawn(caller)
		end
	end)

	if completed then
		return success, result
	end

	local timerThread: thread? = nil
	timerThread = task.delay(timeout, function()
		if not completed then
			timedOut = true
			if workerThread then
				task.cancel(workerThread)
			end
			if coroutine.status(caller) == "suspended" then
				task.spawn(caller)
			end
		end
	end)

	coroutine.yield()

	if timedOut then
		return false, "Timed out after " .. timeout .. " seconds"
	end

	if timerThread then
		task.cancel(timerThread)
	end
	return success, result
end

--// Main
function Loader.Load(Modules: { ModuleScript }, Method: string, VerboseMode: boolean?)
	local function dPrint(message: string)
		if not VerboseMode then
			return
		end
		print("[Loader]", message)
	end

	local Loaded: { ModuleScript } = {}
	local Failed: { ModuleScript } = {}
	local Backup: { ModuleScript } = {}

	dPrint("Loading modules...")
	for _, v in Modules do
		if string.sub(v.Name, -4) == Settings.BackupExtension then
			table.insert(Backup, v)
			continue
		end

		-- timeout for require()
		local reqSuccess, moduleOrErr = runModuleWithTimeout(Settings.Timeout, function()
			return dynamicRequire(v)
		end)

		if not reqSuccess then
			dWarn("Module '" .. v.Name .. "' failed to require or timed out: " .. tostring(moduleOrErr))
			table.insert(Failed, v)
			continue
		end

		if type(moduleOrErr) ~= "table" then
			dWarn("Module '" .. v.Name .. "' did not return a table")
			table.insert(Failed, v)
			continue
		end

		local moduleTable = moduleOrErr :: { [string]: any }
		local targetMethod = moduleTable[Method]

		if type(targetMethod) ~= "function" then
			dWarn("Module '" .. v.Name .. "' does not have the '" .. Method .. "' method")
			table.insert(Failed, v)
			continue
		end

		-- timeout for method()
		local runSuccess, runErr = runModuleWithTimeout(Settings.Timeout, function()
			(targetMethod :: () -> ())()
		end)

		if not runSuccess then
			dWarn("Module '" .. v.Name .. "' errored or timed out during '" .. Method .. "': " .. tostring(runErr))
			table.insert(Failed, v)
			continue
		end

		table.insert(Loaded, v)
		dPrint("Successfully loaded: " .. v.Name)
	end

	return {
		Loaded = Loaded,
		Failed = Failed,
		Backup = Backup
	}
end
return Loader
