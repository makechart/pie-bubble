module.exports =
  pkg:
    name: 'pie-bubble', version: '0.0.1'
    # lite: 不帶 d3 的 base ( 見 @plotdb/chart utils )
    extend: {name: "@makechart/base", path: "lite/index.html"}
    # 排版用 d3-force ( 依相依順序載入, 不需要 d3 core ) 與 d3-force-boundary
    dependencies: [
    * name: \d3-dispatch, version: "3.0.1", path: "dist/d3-dispatch.min.js", async: false
    * name: \d3-quadtree, version: "3.0.1", path: "dist/d3-quadtree.min.js", async: false
    * name: \d3-timer, version: "3.0.1", path: "dist/d3-timer.min.js", async: false
    * name: \d3-force, version: "3.0.0", path: "dist/d3-force.min.js", async: false
    * name: \d3-force-boundary, path: "dist/d3-force-boundary.min.js"
    ]
  init: ({root, context, pubsub}) ->
    pubsub.fire \init, mod: mod {context} .then ~> it.0

mod = ({context}) ->
  {d3,forceBoundary,ldcolor,chart} = context
  fmt = chart.utils.format.d3
  svgns = "http://www.w3.org/2000/svg"
  mk = (p, tag) -> p.appendChild document.createElementNS(svgns, tag)
  kids = (p, sel) -> Array.from(p.querySelectorAll ":scope > #sel")
  # 同 d3.randomLcg ( 移植自 d3-random, ISC ): 沒給種子時用 Math.random 當種子
  lcg = (seed = Math.random!) ->
    [mul, inc, eps] = [0x19660D, 0x3C6EF35F, 1 / 0x100000000]
    state = (if 0 <= seed and seed < 1 => seed / eps else Math.abs(seed)) .|. 0
    -> eps * ((state := (mul * state + inc) .|. 0) .>>>. 0)
  sample: ->
    raw: [0 to 50].map (val) ~>
      name: "N-#val"
      val1: (Math.random! * 100).toFixed(2)
      val2: (Math.random! * 100).toFixed(2)
    binding: do
      name: {key: \name}
      left: {key: \val1, name: \Left}
      right: {key: \val2, name: \Right}
  config: {} <<< chart.utils.config.preset.default <<<
    color:
      left: type: \color, default: \#222
      right: type: \color, default: \#b1003b
  dimension:
    name: {type: \N, name: "name"}
    left: {type: \R, name: "size in left"}
    right: {type: \R, name: "size in right"}
  init: ->
    @tint = tint = new chart.utils.tint!
    @valid = []
    @g = Object.fromEntries <[view legend]>.map ~> [it, @layout.get-group it]
    @tip = new chart.utils.tip {
      root: @root
      node: @root.querySelector('[data-name=tip]')
      view:
        name: ({ctx}) -> if ctx => ctx.name else ''
        value1: ({ctx}) -> if ctx => ctx.value1 else ''
        value2: ({ctx}) -> if ctx => ctx.value2 else ''
      accessor: ({evt}) ~>
        if !(evt.target and data = evt.target.__data__) => return null
        unit = @binding.left.unit or @binding.right.unit or ''
        f = fmt('.3s')
        return {
          name: data.name or ''
          value1: "#{@legend-data.0.text}: #{f data.L}#{unit}"
          value2: "#{@legend-data.1.text}: #{f data.R}#{unit}"
        }
      range: ~> return @layout.get-node \view .getBoundingClientRect!
    }
    @legend = new chart.utils.legend do
      layout: @layout
      name: \legend
      root: @root
      shape: (d) -> @setAttribute \fill, tint.get d.key
      cfg: selectable: true
    @legend.on \select, ~> @bind!; @resize!; @render!

  destroy: -> @tip.destroy!

  parse: ->
    @valid = @data.filter -> !isNaN(it.left + it.right)
    @legend-data = <[left right]>.map ~>
      v = if @binding[it] => (@binding[it].name or @binding[it].key) else it
      {key: v, text: v}
    @legend.data @legend-data

  resize: ->
    @sim = null
    @start!
    @cfg.{}tip
    @cfg.{}color
    @cfg.{}legend
    @tip.toggle(if @cfg.{}tip.enabled? => @cfg.tip.enabled else true)
    @color = [
      @cfg.color.left or (if @color => @color.0 else @tint.get(0)),
      @cfg.color.right or (if @color => @color.1 else @tint.get(1))
    ]
    @tint.set {colors: @color, maps: @legend-data.map(->it.key)}, true
    @legend.config @cfg.legend <<< {selectable: false}
    @legend.update!
    @layout.update false

    @vbox = vbox = @layout.get-box \view
    # 同 d3.randomUniform.source(d3.randomLcg(@seed))(0, 1)
    rng = lcg @seed
    @valid.map (obj) ~>
      [L, R] = [(obj.left >? 0), (obj.right >? 0)]
      r = sum = L + R
      rate = if !sum => 0.5 else R / sum
      [x, y] = [rate * vbox.width, rng! * vbox.height]
      obj <<< {r, sum, rate, L, R, cx: x}
      if !(obj.x?) => obj <<< {x, y}
      if !(obj._x?) => obj <<< {_x: x, _y: y}
      obj

    @rate = 0.85 * # make it slightly smaller. adjust as your wish
      Math.PI / (2 * Math.sqrt(3)) * # wasted space from exterior hexagon to circle
      Math.sqrt(vbox.width * vbox.height / @valid.map(-> Math.PI * (it.r ** 2)).reduce(((a,b) -> a + b),0))
    @valid.map (d,i) ~> d.rr = (d.r * @rate) >? 2

  render: ->
    {binding, tint, rate, legend-data} = @

    {join} = chart.utils.anim
    pj = join root: @g.view, tag: \g, cls: \pie, data: @valid
    pj.exit.map -> it.remove!
    pj.enter.map (n) ->
      n.setAttribute \class, "pie data"
      mk n, \path
      mk n, \path
    kids(@g.view, \g.pie).map (n) ->
      d = n.__data__
      n.setAttribute \transform, "translate(#{d.x} #{d.y})"
      # d3 的 append 會把資料傳給子節點, tip 靠 evt.target 的資料; 這裡自己掛上
      kids(n, \path).map (p, j) ->
        p.__data__ = d
        p.setAttribute \fill, tint.get(legend-data[j].key)
        r = d.rr
        rx  =  r * Math.cos(d.rate * Math.PI)
        ry1 = -r * Math.sin(d.rate * Math.PI)
        ry2 =  r * Math.sin(d.rate * Math.PI)
        f = if d.rate > 0.5 => j else 1 - j
        p.setAttribute \d, [
          "M", rx, ry1,
          "A", r, r, 0, f, j, rx, ry2,
          "L", 0, 0,
          "Z"
        ].join(" ")

    lj = join root: @g.view, tag: \g, cls: \label, data: @valid
    lj.exit.map -> it.remove!
    lj.enter.map (n) ->
      [0,1].map ->
        mk n, \text
          ..setAttribute \text-anchor, \middle
          ..setAttribute \dominant-baseline, \middle
          # 標籤不擋滑鼠, tip 落在底下的 path 上
          ..style.pointerEvents = \none
    kids(@g.view, \g.label).map (n) ->
      d = n.__data__
      n.setAttribute \transform, "translate(#{d.x},#{d.y})"
      kids(n, \text).map (t, j) ->
        t.__data__ = d
        t.setAttribute \dy, if j == 0 => '-.28em' else '.88em'
        t.setAttribute \opacity, (if (d.rr * 2) < "#{(d.sum).toFixed(2)}".length * 7 => 0 else 1)
        t.setAttribute \fill, if ldcolor.hcl(tint.get legend-data.0).l > 60 => \#000 else \#eee
        t.setAttribute \font-size, if j => \.9em else \1.1em
        # 一邊是 0 時比例沒有意義 ( 原本會顯示 Infinity:1 / 1:NaN )
        t.textContent = if j == 1 => d.name
        else if !d.L and !d.R => ''
        else if !d.R => "1:0"
        else if !d.L => "0:1"
        else if d.L > d.R => "#{fmt(\.2s)(d.L / d.R)}:1"
        else "1:#{fmt(\.2s)(d.R / d.L)}"
    @legend.render!

  tick: ->
    pad = @cfg.pad or 5
    box = @vbox
    if !@sim =>
      kickoff = true
      @fc = fc = d3.forceCollide!strength 0.6 .iterations 20 .radius ~> it.rr
      @fg = d3.forceCenter!strength 0.5
      @fb = forceBoundary(
        (-> it.rr + pad), (-> it.rr + pad),
        (~> box.width - it.rr - pad), (~> box.height - it.rr - pad)
      ).strength 0.8
      @sim = d3.forceSimulation!
        # we can't make it center properly so disable it for now.
        #.force \center, @fg
        .force \b, @fb
        .force \collide, @fc
      @sim.stop!
      @sim.alpha 0.9
    @fg.x(box.width / 2)
    @fg.y(box.height / 2)
    @sim.nodes(@valid)
    @sim.tick if kickoff => 10 else 1
    if @sim.alpha! < 0.01 => @stop!
    @valid.map ->
      it._x = it._x + (it.x - it._x) * 0.1
      it._y = it._y + (it.y - it._y) * 0.1
    (kids(@g.view, \g.label) ++ kids(@g.view, \g.pie)).map (n) ->
      d = n.__data__
      n.setAttribute \transform, "translate(#{d._x},#{d._y})"
