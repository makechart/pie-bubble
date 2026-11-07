# Change Logs

## v0.0.3

 - extend the lite base ( `@makechart/base` `lite/index.html`, no d3 ): needs `@makechart/base` >= 0.2.0
   and `@plotdb/chart` >= 3.7.0
   d3 is replaced by `d3-force` ( with `d3-dispatch`, `d3-quadtree`, `d3-timer` ) and `d3-force-boundary`
   transitions run on `chart.anim`, so animation can be recorded frame by frame ( `anim.manual` / `step` )
 - layout is seeded by `seed`, using the same random sequence as before
 - fix bug: ratio text showed `Infinity:1` when a value is 0
 - fix bug: labels blocked hovering ( `pointer-event` instead of `pointer-events` )
 - update test cases


## v0.0.2

 - fix bug: `d3-force-boundary` was used but not loaded
 - explicitly extend `@makechart/base` `d3/index.html`, since it still needs d3
 - add test cases ( `test/index.ls`, run with `npm test` via `@makechart/viewer` )


## v0.0.1

init release
