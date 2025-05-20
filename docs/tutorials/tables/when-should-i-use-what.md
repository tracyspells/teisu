# When should I use `indexes`, `keys`, and `values`?

- `values` should be used when you're dealing with an array or a dictionary where the key doesn't matter, and you want to manipulate values.

- `indexes` should be used when you're dealing with an array with *non-duplicate* values, and you want to rearrange the positions of each value. Some good usecases are:

   - Creating a list of all players
   - Displaying a history of chat messages
   - Toast notifications

-  `keys` can be used for both dictionaries and arrays, but sets (where the keys can be anything and the values are all set to `true`, or some other constant) can benefit from `keys` the most.