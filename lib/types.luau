if not game then
	script = require("../test/relative-string")
end

export type Map<K, V> = { [K]: V }
export type Array<T> = { T }
export type Set<T> = Map<T, (boolean | unknown)>

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
	effect: (() -> ()) | false,
}

export type Molecule<T> = () -> T
export type Flec<T> = (() -> T) & ((value: T | ((T) -> T)) -> T)

export type UsedAs<T> = Molecule<T> | T
export type Use = <T>(target: UsedAs<T>) -> T

return nil
