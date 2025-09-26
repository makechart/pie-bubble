module.exports =
  pkg:
    name: 'pie-bubble', version: '0.0.1'
    extend: {name: "@makechart/base"}
    dependencies: []
  init: ({root, context, pubsub}) ->
    pubsub.fire \init, mod: mod {context} .then ~> it.0

mod = ({context}) ->
  {d3,forceBoundary,ldcolor,chart} = context
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
    @g = Object.fromEntries <[view legend]>.map ~> [it, d3.select(@layout.get-group it)]
    @tip = new chart.utils.tip {
      root: @root
      node: @root.querySelector('[data-name=tip]')
      view:
        name: ({ctx}) -> if ctx => ctx.name else ''
        value1: ({ctx}) -> if ctx => ctx.value1 else ''
        value2: ({ctx}) -> if ctx => ctx.value2 else ''
      accessor: ({evt}) ~>
        if !(evt.target and data = d3.select(evt.target).datum!) => return null
        unit = @binding.left.unit or @binding.right.unit or ''
        fmt = d3.format('.3s')
        return {
          name: data.name or ''
          value1: "#{@legend-data.0.text}: #{fmt data.L}#{unit}"
          value2: "#{@legend-data.1.text}: #{fmt data.R}#{unit}"
        }
      range: ~> return @layout.get-node \view .getBoundingClientRect!
    }
    @legend = new chart.utils.legend do
      layout: @layout
      name: \legend
      root: @root
      shape: (d) -> d3.select(@).attr \fill, tint.get d.key
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
    rng = d3.randomUniform.source(d3.randomLcg(@seed))(0, 1)
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

    @g.view.selectAll \g.pie .data @valid
      ..exit!remove!
      ..enter!append \g .attr \class, "pie data"
        .each ->
          d3.select(@).append \path
          d3.select(@).append \path
    @g.view.selectAll \g.pie
      .each (d,i) ->
        d3.select(@)
          .attr \transform, "translate(#{d.x} #{d.y})"
        d3.select @ .selectAll \path
          .attr \fill, (e,j) -> tint.get(legend-data[j].key)
          .attr \d, (e,j) ~>
            r = d.rr
            rx  =  r * Math.cos(d.rate * Math.PI)
            ry1 = -r * Math.sin(d.rate * Math.PI)
            ry2 =  r * Math.sin(d.rate * Math.PI)
            f = if d.rate > 0.5 => j else 1 - j
            return [
              "M", rx, ry1,
              "A", r, r, 0, f, j, rx, ry2,
              "L", 0, 0,
              "Z"
            ].join(" ")

    @g.view.selectAll \g.label .data @valid
      ..exit!remove!
      ..enter!append \g
        .attr \class, \label
        .each (d,i) ->
          [0,1]
            .map ~> d3.select(@).append \text
            .map ->
              it
                .attr \text-anchor, \middle
                .attr \dominant-baseline, \middle
                .style \pointer-event, \none
    @g.view.selectAll \g.label
      .attr \transform, (d,i) -> "translate(#{d.x},#{d.y})"
      .each (d,i) ->
        d3.select(@).selectAll \text
          .attr \dy, (e,i) -> if i == 0 => '-.28em' else '.88em'
          .attr \opacity, (if (d.rr * 2) < "#{(d.sum).toFixed(2)}".length * 7 => 0 else 1)
          .attr \fill, (d,i) -> if ldcolor.hcl(tint.get legend-data.0).l > 60 => \#000 else \#eee
          .attr \font-size, (d,i) -> if i => \.9em else \1.1em
          .text (e,j) ->
            if j == 1 => return d.name
            text = if d.L > d.R => "#{d3.format(\.2s)(d.L / d.R)}:1"
            else "1:#{d3.format(\.2s)(d.R / d.L)}"
            return text
            #ret = d3.format('.3s')(d.sum)
            #if ret => ret = "#{ret}#{binding.left.unit or binding.right.unit or ''}"
            #return ret
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
    @g.view.selectAll \g.label
      .attr \transform, (d,i) -> "translate(#{d._x},#{d._y})"
    @g.view.selectAll \g.pie
      .attr \transform, (d,i) -> "translate(#{d._x},#{d._y})"
