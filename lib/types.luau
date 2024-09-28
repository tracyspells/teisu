export type Map<K, V> = { [K]: V }
export type WeakMap<K, V> = typeof(setmetatable({} :: Map<K, V>, { __mode = "k" }))

export type Array<T> = { T }
export type Set<T> = Map<T, (boolean | unknown)>

export type Listener<T> = (T, T) -> ()

---
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
	effect: (() -> T) | (() -> ()) | false,
}

export type Molecule<T> = (() -> T) 
export type Flec<T> = (() -> T) & ((value: T | ((T) -> T)) -> T)

export type UsedAs<T> = Molecule<T> | T
export type Use = <T>(target: UsedAs<T>) -> T

---

export type NetworkPayload = {
	type: "diff" | "full",
	contents: Map<any, any>,
}

export type ServerSyncer = {
	hydrate: (self: ServerSyncer, player: Player) -> (),
	connect: (self: ServerSyncer, callback: (player: Player, ...NetworkPayload) -> ()) -> () -> (),
}

export type ServerOptions = {
	flecs: Map<string, Flec<any>>,
	interval: number?,
	preserveHistory: boolean?,
}

export type MockServerSyncer = ServerSyncer & {
	_sendDiff: (self: ServerSyncer, player: Player) -> (),
}

export type ClientSyncer = {
	sync: (self: ClientSyncer, ...NetworkPayload) -> (),
}

export type ClientOptions = {
	flecs: Map<string, Flec<any>>,
}

return nil
