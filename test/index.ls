# pie-bubble 的 test case ( @makechart/viewer 的 mctest )
rnd = mctest.random 9
data =
  basic:
    raw: [0 til 20].map (i) -> {name: "N-#i", l: Math.round(rnd! * 100), r: Math.round(rnd! * 100)}
    binding: {name: {key: \name}, left: {key: \l, name: \Left}, right: {key: \r, name: \Right}}
mctest.suite {size: [480, 320], data, cases: [{name: "basic"}]}
