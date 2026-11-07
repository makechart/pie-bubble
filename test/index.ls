# pie-bubble 的 test case ( @makechart/viewer 的 mctest )
# 每份資料用自己的種子, 跟產生的先後順序無關
mk = (n, seed = n) ->
  rnd = mctest.random seed
  raw: [0 til n].map (i) -> {name: "N-#i", l: Math.round(rnd! * 100), r: Math.round(rnd! * 100)}
  binding: {name: {key: \name}, left: {key: \l, name: \Left}, right: {key: \r, name: \Right}}
# 初始位置用 d3.randomLcg(@seed), @seed 沒設時種子來自 Math.random. 換成固定種子後重排 ( resize ),
# 位置清掉重排, 再讓模擬跑完 ( alpha 從 0.9 降到 0.01 約 200 步 ). lite 版推 anim 的時鐘, d3 版等真實時間.
# 種子留到最後一步才換回, 期間的 resize 也用同一組亂數
_random = Math.random
layout = [
  (c) ->
    Math.random = mctest.random 1
    # 初始的 y 用 d3.randomLcg(@seed); 直接給種子, 不靠 Math.random 被呼叫的次數
    c.seed = 7
    # 位置只在第一次 resize 時決定 ( 之後沿用 ), 先清掉, 連同模擬留下的速度
    c.valid.map (d) -> <[x y _x _y vx vy index]>.map (k) -> delete d[k]
    c.resize!; c.render!
  (c, ctx) ->
    if c.anim => for i from 0 til 300 => c.anim.step 16
    else ctx.wait 6000
  -> Math.random = _random
]
pick = (keys) -> (c) ->
  c.legend.select keys
  c.bind!; c.resize!; c.render!

# 滑到圖形上: tip 讀 evt.target 的資料
hover = (sel, idx = 0) -> (c, ctx) ->
  n = ctx.root.querySelectorAll(sel)[idx]
  r = n.getBoundingClientRect!
  n.dispatchEvent new MouseEvent(\mousemove, {bubbles: true, clientX: Math.round(r.x + r.width / 2), clientY: Math.round(r.y + r.height / 2)})

mctest.suite do
  size: [480, 320]
  data:
    basic: mk 20, 9
    few: mk 5
    zero: do ->
      d = mk 8
      d.raw.1 <<< {l: 98, r: 0}
      d.raw.2 <<< {l: 0, r: 0}
      d
  cases:
    * name: "basic", data: \basic, steps: layout
    * name: "few", data: \few, steps: layout
    * name: "zero", data: \zero, steps: layout
    * name: "color", data: \few, config: {color: {left: \#0a0, right: \#00f}}, steps: layout
    * name: "legend:bottom", data: \basic, config: {legend: {position: \bottom}}, steps: layout
    * name: "hover", data: \basic, steps: [(layout.0), (layout.1), (hover 'g.pie path', 3), (layout.2)]

# lite 版才有: 模擬收斂的中間格
mctest.suite do
  size: [480, 320]
  data: basic: mk 20, 9
  cases:
    * name: "anim:layout-frames", data: \basic
      steps:
        * layout.0
        * (c, ctx) ->
            for i from 1 to 3
              for j from 0 til 10 => c.anim.step 16
              ctx.capture "f#{i * 10}"
        * layout.2
