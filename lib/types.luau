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
	___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value: T | false,
	eager: boolean?,
	isPartOfBatch: boolean?,
	nickname: string,
	effect: (() -> ()) | false,
}

export type Molecule<T> = () -> T
export type Flec<T> = (() -> T) & ((value: T | ((T) -> T)) -> T)

export type Spring<T> = Molecule<T> & {
	impulse: (self: Spring<T>, delta: T) -> (),
	setPosition: (self: Spring<T>, newValue: T) -> (),
	setVelocity: (self: Spring<T>, newValue: T) -> (),
	onComplete: (callback: (value: T) -> ()) -> Cleanup,
}

export type UsedAs<T> = Molecule<T> | T
export type Use = <T>(target: UsedAs<T>) -> T

export type PatchOperation = "add" | "remove" | "replace"
export type Patch<K, V> = {
	op: PatchOperation,
	path: { K },
	value: V | NONE,
}

export type SyncPayload = {
	type: "init",
	data: { [string | number]: any },
} | {
	type: "patch",
	data: { Patch<string | number, any> },
}

return nil
