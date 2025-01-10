local spring = require("@spring/")

return table.freeze({
    spring = spring.spring,
    is_spring = spring.is_spring,
    step_springs = spring.step,
})