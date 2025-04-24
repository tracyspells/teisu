export type CASE = (name: string) -> ()
export type CHECK = <T>(value: T) -> T
export type CHECK_EXPECT_ERROR = <T..., U...>(fn: (T...) -> U...) -> ()
export type SKIP = () -> ()

export type TEST_FN = (SKIP, CASE, CHECK, CHECK_EXPECT_ERROR) -> ()

export type TESTS = { {name: string, fn: TEST_FN } }

return nil