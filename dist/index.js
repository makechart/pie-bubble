(function(){
  var mod;
  module.exports = {
    pkg: {
      name: 'pie-bubble',
      version: '0.0.1',
      extend: {
        name: "base",
        version: "0.0.1"
      },
      dependencies: []
    },
    init: function(arg$){
      var root, context, pubsub;
      root = arg$.root, context = arg$.context, pubsub = arg$.pubsub;
      return pubsub.fire('init', {
        mod: mod({
          context: context
        })
      }).then(function(it){
        return it[0];
      });
    }
  };
  mod = function(arg$){
    var context, d3, forceBoundary, ldcolor, chart, ref$;
    context = arg$.context;
    d3 = context.d3, forceBoundary = context.forceBoundary, ldcolor = context.ldcolor, chart = context.chart;
    return {
      sample: function(){
        return {
          raw: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50].map(function(val){
            return {
              name: "N-" + val,
              val1: (Math.random() * 100).toFixed(2),
              val2: (Math.random() * 100).toFixed(2)
            };
          }),
          binding: {
            name: {
              key: 'name'
            },
            left: {
              key: 'val1',
              name: 'Left'
            },
            right: {
              key: 'val2',
              name: 'Right'
            }
          }
        };
      },
      config: (ref$ = import$({}, chart.utils.config.preset['default']), ref$.color = {
        left: {
          type: 'color',
          'default': '#222'
        },
        right: {
          type: 'color',
          'default': '#b1003b'
        }
      }, ref$),
      dimension: {
        name: {
          type: 'N',
          name: "name"
        },
        left: {
          type: 'R',
          name: "size in left"
        },
        right: {
          type: 'R',
          name: "size in right"
        }
      },
      init: function(){
        var tint, this$ = this;
        this.tint = tint = new chart.utils.tint();
        this.valid = [];
        this.g = Object.fromEntries(['view', 'legend'].map(function(it){
          return [it, d3.select(this$.layout.getGroup(it))];
        }));
        this.tip = new chart.utils.tip({
          root: this.root,
          node: this.root.querySelector('[data-name=tip]'),
          view: {
            name: function(arg$){
              var ctx;
              ctx = arg$.ctx;
              if (ctx) {
                return ctx.name;
              } else {
                return '';
              }
            },
            value1: function(arg$){
              var ctx;
              ctx = arg$.ctx;
              if (ctx) {
                return ctx.value1;
              } else {
                return '';
              }
            },
            value2: function(arg$){
              var ctx;
              ctx = arg$.ctx;
              if (ctx) {
                return ctx.value2;
              } else {
                return '';
              }
            }
          },
          accessor: function(arg$){
            var evt, data, unit, fmt;
            evt = arg$.evt;
            if (!(evt.target && (data = d3.select(evt.target).datum()))) {
              return null;
            }
            unit = this$.binding.left.unit || this$.binding.right.unit || '';
            fmt = d3.format('.3s');
            return {
              name: data.name || '',
              value1: this$.legendData[0].text + ": " + fmt(data.L) + unit,
              value2: this$.legendData[1].text + ": " + fmt(data.R) + unit
            };
          },
          range: function(){
            return this$.layout.getNode('view').getBoundingClientRect();
          }
        });
        this.legend = new chart.utils.legend({
          layout: this.layout,
          name: 'legend',
          root: this.root,
          shape: function(d){
            return d3.select(this).attr('fill', tint.get(d.key));
          },
          cfg: {
            selectable: true
          }
        });
        return this.legend.on('select', function(){
          this$.bind();
          this$.resize();
          return this$.render();
        });
      },
      destroy: function(){
        return this.tip.destroy();
      },
      parse: function(){
        var this$ = this;
        this.valid = this.data.filter(function(it){
          return !isNaN(it.left + it.right);
        });
        this.legendData = ['left', 'right'].map(function(it){
          var v;
          v = this$.binding[it] ? this$.binding[it].name || this$.binding[it].key : it;
          return {
            key: v,
            text: v
          };
        });
        return this.legend.data(this.legendData);
      },
      resize: function(){
        var ref$, vbox, rng, this$ = this;
        this.sim = null;
        this.start();
        (ref$ = this.cfg).tip || (ref$.tip = {});
        (ref$ = this.cfg).color || (ref$.color = {});
        (ref$ = this.cfg).legend || (ref$.legend = {});
        this.tip.toggle(((ref$ = this.cfg).tip || (ref$.tip = {})).enabled != null ? this.cfg.tip.enabled : true);
        this.color = [
          this.cfg.color.left || (this.color
            ? this.color[0]
            : this.tint.get(0)), this.cfg.color.right || (this.color
            ? this.color[1]
            : this.tint.get(1))
        ];
        this.tint.set({
          colors: this.color,
          maps: this.legendData.map(function(it){
            return it.key;
          })
        }, true);
        this.legend.config((ref$ = this.cfg.legend, ref$.selectable = false, ref$));
        this.legend.update();
        this.layout.update(false);
        this.vbox = vbox = this.layout.getBox('view');
        rng = d3.randomUniform.source(d3.randomLcg(this.seed))(0, 1);
        this.valid.map(function(obj){
          var ref$, L, R, r, sum, rate, x, y;
          ref$ = [(ref$ = obj.left) > 0 ? ref$ : 0, (ref$ = obj.right) > 0 ? ref$ : 0], L = ref$[0], R = ref$[1];
          r = sum = L + R;
          rate = !sum
            ? 0.5
            : R / sum;
          ref$ = [rate * vbox.width, rng() * vbox.height], x = ref$[0], y = ref$[1];
          obj.r = r;
          obj.sum = sum;
          obj.rate = rate;
          obj.L = L;
          obj.R = R;
          obj.cx = x;
          if (!(obj.x != null)) {
            obj.x = x;
            obj.y = y;
          }
          if (!(obj._x != null)) {
            obj._x = x;
            obj._y = y;
          }
          return obj;
        });
        this.rate = 0.85 * Math.PI / (2 * Math.sqrt(3)) * Math.sqrt(vbox.width * vbox.height / this.valid.map(function(it){
          return Math.PI * Math.pow(it.r, 2);
        }).reduce(function(a, b){
          return a + b;
        }, 0));
        return this.valid.map(function(d, i){
          var ref$;
          return d.rr = (ref$ = d.r * this$.rate) > 2 ? ref$ : 2;
        });
      },
      render: function(){
        var binding, tint, rate, legendData, x$, y$;
        binding = this.binding, tint = this.tint, rate = this.rate, legendData = this.legendData;
        x$ = this.g.view.selectAll('g.pie').data(this.valid);
        x$.exit().remove();
        x$.enter().append('g').attr('class', "pie data").each(function(){
          d3.select(this).append('path');
          return d3.select(this).append('path');
        });
        this.g.view.selectAll('g.pie').each(function(d, i){
          d3.select(this).attr('transform', "translate(" + d.x + " " + d.y + ")");
          return d3.select(this).selectAll('path').attr('fill', function(e, j){
            return tint.get(legendData[j].key);
          }).attr('d', function(e, j){
            var r, rx, ry1, ry2, f;
            r = d.rr;
            rx = r * Math.cos(d.rate * Math.PI);
            ry1 = -r * Math.sin(d.rate * Math.PI);
            ry2 = r * Math.sin(d.rate * Math.PI);
            f = d.rate > 0.5
              ? j
              : 1 - j;
            return ["M", rx, ry1, "A", r, r, 0, f, j, rx, ry2, "L", 0, 0, "Z"].join(" ");
          });
        });
        y$ = this.g.view.selectAll('g.label').data(this.valid);
        y$.exit().remove();
        y$.enter().append('g').attr('class', 'label').each(function(d, i){
          var this$ = this;
          return [0, 1].map(function(){
            return d3.select(this$).append('text');
          }).map(function(it){
            return it.attr('text-anchor', 'middle').attr('dominant-baseline', 'middle').style('pointer-event', 'none');
          });
        });
        this.g.view.selectAll('g.label').attr('transform', function(d, i){
          return "translate(" + d.x + "," + d.y + ")";
        }).each(function(d, i){
          return d3.select(this).selectAll('text').attr('dy', function(e, i){
            if (i === 0) {
              return '-.28em';
            } else {
              return '.88em';
            }
          }).attr('opacity', d.rr * 2 < (d.sum.toFixed(2) + "").length * 7 ? 0 : 1).attr('fill', function(d, i){
            if (ldcolor.hcl(tint.get(legendData[0])).l > 60) {
              return '#000';
            } else {
              return '#eee';
            }
          }).attr('font-size', function(d, i){
            if (i) {
              return '.9em';
            } else {
              return '1.1em';
            }
          }).text(function(e, j){
            var text;
            if (j === 1) {
              return d.name;
            }
            text = d.L > d.R
              ? d3.format('.2s')(d.L / d.R) + ":1"
              : "1:" + d3.format('.2s')(d.R / d.L);
            return text;
          });
        });
        return this.legend.render();
      },
      tick: function(){
        var pad, box, kickoff, fc;
        pad = this.cfg.pad || 5;
        box = this.vbox;
        if (!this.sim) {
          kickoff = true;
          this.fc = fc = d3.forceCollide().strength(0.6).iterations(20).radius(function(it){
            return it.rr;
          });
          this.fg = d3.forceCenter().strength(0.5);
          this.fb = forceBoundary(function(it){
            return it.rr + pad;
          }, function(it){
            return it.rr + pad;
          }, function(it){
            return box.width - it.rr - pad;
          }, function(it){
            return box.height - it.rr - pad;
          }).strength(0.8);
          this.sim = d3.forceSimulation().force('b', this.fb).force('collide', this.fc);
          this.sim.stop();
          this.sim.alpha(0.9);
        }
        this.fg.x(box.width / 2);
        this.fg.y(box.height / 2);
        this.sim.nodes(this.valid);
        this.sim.tick(kickoff ? 10 : 1);
        if (this.sim.alpha() < 0.01) {
          this.stop();
        }
        this.valid.map(function(it){
          it._x = it._x + (it.x - it._x) * 0.1;
          return it._y = it._y + (it.y - it._y) * 0.1;
        });
        this.g.view.selectAll('g.label').attr('transform', function(d, i){
          return "translate(" + d._x + "," + d._y + ")";
        });
        return this.g.view.selectAll('g.pie').attr('transform', function(d, i){
          return "translate(" + d._x + "," + d._y + ")";
        });
      }
    };
  };
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
