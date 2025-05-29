export type Map<K, V> = { [K]: V }
export type Array<T> = { T }
export type Set<T> = Map<T, (boolean | unknown)>

export type NONE = { __none: "__none" }

export type LAB = {
	L: number,
	A: number,
	B: number,
}

export type Cleanup = () -> ()

export type NodeState = "clean" | "check" | "dirty"
export type NodeNonCleanState = "check" | "dirty"

export type Node<T> = {
	children: Set<Node<T>>,
	parents: Set<Node<T>>,
	state: NodeState,
	createdAt: number,
	cache: T | false,
	eager: boolean?,
	isPartOfBatch: boolean?,
	nickname: string,
	effect: (() -> ()) | false,
}

export type Molecule<T> = () -> T
export type Flec<T> = (() -> T) & ((value: T) -> T) & ((value: (T) -> T) -> T)

export type Spring<T> = Molecule<T> & {
	impulse: (self: Spring<T>, delta: T) -> (),
	setPosition: (self: Spring<T>, newValue: T) -> (),
	setVelocity: (self: Spring<T>, newValue: T) -> (),
	onComplete: (callback: (value: T) -> ()) -> Cleanup,
}

export type Tween<T> = Molecule<T> & {
    onComplete: (callback: (value: T) -> ()) -> Cleanup,
}

export type Context<T> = {
	provide: <V>(T, (() -> V)) -> V,
	consume: () -> T,
}

export type UsedAs<T> = T | () -> T
export type Use = <T>(target: UsedAs<T>) -> T

export type PatchOperation = "add" | "remove" | "replace"
export type Patch<K, V> = {
	op: PatchOperation,
	path: { K },
	value: V | NONE,
}

export type Animatable = 
	number | boolean | UDim | UDim2 | Rect | Vector2 | Vector3 | CFrame | Color3 
	| NumberRange | NumberSequenceKeypoint | ColorSequenceKeypoint

export type EasingDirection = "In" | "Out" | "InOut"
export type EasingStyle = "Linear" | "Cubic" | "Bounce" | "Elastic" 
	| "Back" | "Sine" | "Smooth" | "Quad" | "Quart" | "Quint" | "Exponential" | "Circular"

export type SyncPayload = {
	type: "init",
	data: { [string | number]: any },
} | {
	type: "patch",
	data: { Patch<string | number, any> },
}

export type EqualityFn<T> = (old: T, new: T) -> boolean

export type Animated<T> = Spring<T> | Tween<T>
export type Destroyable = { destroy: (any) -> () } | { Destroy: (any) -> () }
export type Disconnectable = { disconnect: (any) -> () } | { Disconnect: (any) -> () }

export type Task = 
	Instance 
	| () -> () 
	| Animated<any> 
	| Destroyable 
	| Disconnectable 
	| RBXScriptConnection

return nil
