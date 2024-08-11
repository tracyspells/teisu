export type Dictionary<K, V> = { [K]: V }
export type AnyDictionary = Dictionary<any, any>

export type Array<T> = { T }

export type Set<T> = { [T]: boolean }
export type WeakMap<K, V> = typeof(setmetatable({} :: Dictionary<K, V>, { __mode = "k" }))

---

export type Node = {
	children: Set<Node>,
	parents: Set<Node>,
	state: "clean" | "dirty" | "busy",
	createdAt: number,
	timeliness: "lazy" | "eager",
	version: number,
	_evaluate: (Node) -> boolean,
}

export type StateObject<T> = Node & {
	implements: Set<string>,
	_value: T,
}

export type Value<T> = StateObject<T> & {
	_initialValue: T,
	implements: { node: true, value: true },
	reset: (self: Value<T>) -> (),
	set: (self: Value<T>, setTo: T | ((T) -> T)) -> (),
}

export type Computed<T> = StateObject<T> & {
	implements: { node: true, computed: true },
	_processor: (use: (Computed<T>) -> T) -> T,
}

export type Listener<T> = (T, T) -> ()
export type Compare = <T>(new: T, old: T) -> boolean

export type Use = <T>(Value<T> | Computed<T>) -> T
export type UsedAs<T> = Value<T> | Computed<T> | T

---

export type NetworkPayload = {
	type: "diff" | "full",
	contents: Dictionary<string, any>,
}

export type ClientSyncer = {
	sync: (self: ClientSyncer, ...NetworkPayload) -> (),
}
export type ServerSyncer = {
	hydrate: (self: ServerSyncer, player: Player) -> (),
	connect: (self: ServerSyncer, callback: (player: Player, ...NetworkPayload) -> ()) -> () -> (),
}

export type ServerOptions = {
	values: Dictionary<string, Value<any>>,
	interval: number?,
	preserveHistory: boolean?,
}

export type MockServerSyncer = ServerSyncer & {
	_sendDiff: (self: ServerSyncer, player: Player) -> (),
}

return nil
