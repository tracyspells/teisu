# Springs

Springs follow the value of other state objects by simulating a physical model of a spring. This can be useful in many situations.

## Usage

To create a spring, import `Teisu.spring` in your code and pass it a `flec` to move towards.

```luau
local flec = Teisu.flec
local spring = Teisu.spring

local goal = flec(1)
local animated = spring(goal)
```

You can access the spring's value at any time:

```luau
print(animated()) --> 0.24775...

-- alternatively, you can use `peek()`
print(peek(animated))
```

To configure how the spring moves, you can give it `speed` and `damping` arguments. Both of these are optional, and can be state objects if desired.

```luau
local goal = flec(1)
local speed = flec(1.5)
local damping = 0.5 -- the damping ratio

local animated = spring(goal, speed, damping)
```

You can set the spring's position and velocity at any time:

```luau
animated:setPosition(6) --> snaps the spring to 6
animated:setVelocity(2) --> from here, move up 2 units per second
```

Additionally, you can give your spring a burst of speed with `:impulse()`:

```luau
animated:impulse(5)
```

To check if a spring has reached it's destination, you can use `.onCompleted()`:

```luau
animated.onComplete(function(goal: number)
    print("we've reached our goal!")
end)
```

You can use many different kinds of values as springs, not just numbers.

<!--@include: @api/animation.md{5,9}-->

The above is a list of all supported value types to animate.

## Speed

The `speed` of the spring dictates how fast the spring is going.

-  Speeds less than `1` are very quick. Perfect for snappy and quick animations.

-  Speeds equal to `1` (which is the default spring speed) are fast.

`speed` gradually slows down the higher you go. For example, a speed of `20` can make your spring progress very slowly.

## Damping Ratio

The damping ratio (or `damping`, for short) of your spring influences how much friction is applied.

-   Lower values oscillate up and down, allowing free movement

-   Higher values restrict movement


### Zero Damping

When `damping` is set to values less than `0`, no friction is applied. The spring will go on forever, regardless of speed.

### Underdamping

When `damping` is set to values between `0-1`, some friction is applied and the spring will slightly overshoot its target. The spring will eventually reach its goal.

### Critical Damping

When `damping` is set to `1` (the default value), enough friction is applied to the spring in order to reach its goal as quickly as possible without overshooting.

This is known as critical damping.

### Overdamping

If `damping` is greater than `1`, the spring will progress slowly towards its goal due to excessive friction. It will behave similarly to honey being poured down from the bottle that the liquid is in onto a spoon.






