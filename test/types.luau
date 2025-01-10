export type CASE = (name: string) -> ()
export type CHECK = <T>(value: T) -> T

export type TEST_FN = (CASE, CHECK) -> ()

export type TESTS = { {name: string, fn: TEST_FN } }

return nil