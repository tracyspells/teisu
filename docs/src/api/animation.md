# Animation

## Animatable

```luau
type Animatable = 
    number | boolean | UDim | UDim2 | Rect | Vector2 | Vector3 | CFrame | Color3
    | NumberRange | ColorSequenceKeypoint | NumberSequenceKeypoint
```

## EasingStyle

```luau
type EasingStyle = "Linear" | "Cubic" | "Bounce" | "Elastic" 
	| "Back" | "Sine" | "Smooth" | "Quad" | "Quart" | "Quint" | "Exponential" | "Circular"
```

## EasingDirection

```luau
type EasingDirection = "In" | "Out" | "InOut"
```

## tween()

```luau
type Derivable<T> = Molecule<T> | T
type Molecule<T> = () -> T

type Cleanup = () -> ()

type TweenProps = {
    duration: Derivable<number>,
    delay: Derivable<number>?,
    style: Derivable<EasingStyle>?
    direction: Derivable<EasingDirection>?,
    reverses: Derivable<boolean>?,
	repeats: Derivable<number>?,
}


type Tween<T = Animatable> = Molecule<T> & {
    onComplete: (callback: (value: T) -> ()) -> Cleanup,
}

function tween<T>(
    goal: Molecule<T & Animatable>,
    props: TweenProps
): Tween<T>
```

### Parameters

-   `goal`: A molecule that represents the goal the tween should follow.

-   `props`: Determines the easing curve that the tween will follow.

    -   `duration`: How long (in seconds) it takes to go from point A to B Defaults to `1` second.

    -   `style`: The style in which the tween executes.

    -   `direction`: The direction in which the tween executes.

    -   `reverses`: Whether or not the tween interpolates in reverse once the initial tween completes.

    -   `delay`: Delays the tween before it begins, in seconds.

    -   `repeats`: Number of times the tween repeats. `-1` indicates indefinite repetition.

### Returns

Returns a tween object with the following methods:

-   `.onComplete(listener)`: Calls `listener` whenever a tween finishes animating. Returns a function that disconnects the listener.

Call the tween object to get its current value.


## spring()

Creates an object with a value always moving towards the goal value.

```luau
type Derivable<T> = Molecule<T> | T
type Molecule<T> = () -> T

type Cleanup = () -> ()

type Spring<T = Animatable> = Molecule<T> & {
    impulse: (self: Spring<T>, delta: T) -> (),
    setPosition: (self: Spring<T>, newPosition: T) -> (),
    setVelocity: (self: Spring<T>, newVelocity: T) -> (),
    onComplete: (callback: (value: T) -> ()) -> Cleanup,
}

function spring<T>(
    goal: Molecule<T & Animatable>,
    speed: Derivable<number>?,
    damping: Derivable<number>?
): Spring<T>
```

### Parameters

-   `goal`: A molecule that represents the goal the spring should follow.

-   **optional** `speed`: The amount of time in seconds it takes for the spring to complete one full cycle if undamped. Defaults to `1`.

-   **optional** `damping`: The amount of resistance applied to the spring.

    -   \> 1 = Overdamped: slowly reaches target without any overshoot.

    -   1 = Critically damped: reaches target without any overshoot.

    -   <1 = Underdamped: reaches target with some overshoot.

    -   0 = Undamped: never stabilizes, oscillates forever.

    Defaults to `1` (Critically damped).

### Returns

Returns a spring object with the following methods:

-   `:impulse(delta)`: Adds to the spring's velocity without changing its position. The `delta` must have the same type as the `goal` state.

-   `:setPosition(newPosition)`: Immediately snaps the spring to the given position. The `newPosition` must have the same type as the `goal` state.

-   `:setVelocity(newVelocity)`: Overwrites the spring's velocity without changing its position. The `newVelocity` must have the same type as the `goal` state.

-   `.onComplete(listener)`: Calls `listener` whenever a spring finishes stabilizing. Returns a function that disconnects the listener.

Call the spring object to get its current value.
