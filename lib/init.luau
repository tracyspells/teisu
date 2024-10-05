if not game then
	script = require("../test/relative-string")
end

local types = require(script.types)
local flec = require(script.flec)
local subscribe = require(script.subscribe)
local effect = require(script.effect)
local observe = require(script.observe)
local computed = require(script.computed)
local peek = require(script.peek)
local mapped = require(script.mapped)
local batch = require(script.batch)

export type Flec<T> = types.Flec<T>
export type Molecule<T> = types.Molecule<T>

return table.freeze({
	flec = flec,
	computed = computed,
	effect = effect,
	mapped = mapped,
	observe = observe,
	subscribe = subscribe,
	peek = peek,
	batch = batch,
})
