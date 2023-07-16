# Hoverdown

Improves support for LSP hover documentation by properly parsing and
highlighting markdown.

## Installation

Install with your favorite package manager (e.g.
[lazy.nvim](https://github.com/folke/lazy.nvim)).

```lua
{
  "mskelton/hoverdown.nvim"
  config = function()
    require('hoverdown').setup()
  end
}
```

## Overrides

You can apply overrides to the parsed text blocks if you would like to perform
custom replacements. You can provide an `overrides` table which maps to file
types that you would like to perform overrides for. The example below shows how
to perform a basic override for Go files.

```lua
require('hoverdown').setup({
    overrides = {
        go = function(blocks)
            for _, block in ipairs(blocks) do
                if block.type == "line" then
                    block.value = block.value:gsub(" on pkg.go.dev", "")
                end
            end

            return blocks
        end,
    },
})
```

You can also use the `*` override to apply overrides to all file types.

```lua
require('hoverdown').setup({
    overrides = {
        ['*'] = function(blocks) end,
    },
})
```


## Acknowledgements

Thanks to [folke](https://github.com/folke) and
[noice.nvim](https://github.com/folke/noice.nvim) for the original work from
which this project was based on!
