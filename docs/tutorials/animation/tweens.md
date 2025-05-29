# Tweens

Tweens follow the value of other state objects by using a pre-made animation curve. They are used for simple and predictable animations.

## Usage

To create a tween, import `Teisu.tween` in your code and pass it a `flec` to move towards.

```luau
local flec = Teisu.flec
local tween = Teisu.tween

local goal = flec(1)
local animated = tween(goal)
```

You can access the tween's value at any time:

```luau
print(animated()) --> 0.24775...

-- alternatively, you can use `peek()`
print(peek(animated))
```

To configure how a tween animates, you can provide a [property table](./tweens.md#tween-properties) to change the shape of the animation curve.  This property table is optional, and each property can be a molecule if desired.

```luau {2}
local goal = flec(1)
local props = { duration = 0.5, style = "Sine" }

local animated = tween(goal, props)
```

To check if a tween has reached it's destination, you can use `.onComplete()`:

```luau
animated.onComplete(function(goal: number)
    print("we've reached our goal!")
end)
```

If you're outside of a scope, you can destroy a tween via `Teisu.cleanup`.

```luau {2}
task.wait(5)
Teisu.cleanup(animated)
```

You can use many different kinds of values as tweens, not just numbers.

<!--@include: @api/animation.md{5,9}-->

The above is a list of all supported value types to animate.

## Tween Properties

```luau
local props = {
    duration = 1,
    style = "Linear",
    direction = "In",
    delay = 0,
    repeats = 0,
    reverses = false,
}
```

### Duration

This specifies how long it should take for the tween to animate to its goal, in seconds.

### Style

You can select various, pre-made animation curves based on the following options: 

<!--@include: @api/animation.md{13,16}-->

### Direction

This can be set to one of three values to control how the tween starts and stops:

-   `"In"` makes the tween animate in smoothly.

-   `"Out"` makes the tween animate out smoothly.

-   `"InOut"` makes the tween animate in *and* out smoothly.

### Delay

This specifies how long it takes before the tween *actually* begins. This isn't a true delay; it only makes the animation longer.

### Repeats

This property, once set, can loop the animation a number of times. Setting `repeats` to `-1` will loop the animation infinitely.

### Reverses

If set to `true`, the animation will reverse and snaps to the goal at the end.

