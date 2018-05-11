<style scoped>
    .barcode-div >>> .barcode {
        position: relative;
        height: 100%;
        width: 100%;
    }
    .barcode-div >>> .barcode .extent {
        fill: #000;
        fill-opacity: .2;
        stroke: #fff;
    }
    .barcode-outer >>> .barcode .axis line, .barcode-div >>> .barcode .axis path {
        fill: none;
        stroke: #222;
        shape-rendering: crispEdges;
    }

    div >>> barcode-tooltip {
      /* position: absolute; */
      /* text-align: left; */
      font-family: sans-serif;
      font-size: 11px;
      pointer-events: none;
      color: #a6a6a6;
      opacity: 0;
  }

    .barcode-div {
        padding-top: 10px;
        padding-bottom: 25px;

    }
</style>

<template>
    <div>
        <div class='barcode-div' ref='barcode'>
        </div>
        <div class='barcode-tooltip'></div>
    </div>
</template>

<script lang='coffee'>

css = {axis: 'axis', barcode: 'barcode'}

#Make barcode plot object
class BarcodePlot
    constructor: (@opts={}) ->
        this.name ?= 'barcode'
        this.opts.xaxis_loc ?= 'zero'
        this.opts.yaxis_loc ?= 'left'
        this.opts.colouring ?= () -> 'blue'
        this.opts.infoCols ?= ''
        this.opts.height ?= 200
        this.data = this.opts.data
        this.barcodeCol = this.opts.barcodeCol

        this.elem = d3.select(this.opts.elem).append('div')
        # this.elem.attr('class'. css.barcode)

        if this.opts.width
            this.elem.style('width', this.opts.width+'px')
        if this.opts.height
            this.elem.style('height', this.opts.height+'px')


        #Initialise SVG's
        # May want to consider using canvas because 11K+ rectangles is a lot
        this.svg = this.elem.append('svg')
        this.gRect = this.svg

        #If brush - Initialise it here - No brush support yet
        this.dispatch = d3.dispatch('mouseover', 'mouseout')
        #This calls the resize which calls the redraw
        this.resize()

    resize: () ->
        this.width = this.opts.width || this.elem.node().clientWidth
        this.height = this.opts.height || this.elem.node().clientHeight
        this.svg.attr('width', this.width)
                .attr('height', this.height)

        this.redraw()

    #returns the appropriate redraw function for double/single plots
    redraw: () ->
        if this.opts.double
            this.redraw_double()
        else
            this.redraw_single()

    redraw_single: () ->
        if !this.data
            return
        this.x_val = x_val = (d) =>
            this.barcodeCol.get(d)

        xdomain = d3.extent(this.data, (d) => x_val(d)).map((x) => x)

        this.xScale = xScale = d3.scale.linear()
            .domain([0, this.data.length])
            .range([this.opts.margin_l, this.width-this.opts.margin_l-this.opts.margin_r])

        this.yScale = yScale = d3.scale.ordinal()
            .domain(['bottom', 'mid', 'top'])
            .rangeRoundPoints([0, this.height])

        # Kept - stuff that passes filter
        # rect_new - New points to add
        # .exit - Remove old
        # .enter - Add new
        kept = this.data.filter((d) => this.opts.filter(d))
        rects = this.svg.selectAll('rect')
                        .data(kept.reverse())
        rects.exit().remove()

        div = d3.select('.barcode-tooltip')

        #Append data
        rects.enter().append('rect')
                .style('fill', 'blue')
                .attr('height', 75)
                .attr('width', 1)
                .attr('y', 75)

        #dispatch for hover event
        rects.attr('x',(d) => xScale(x_val(d)))
                .attr('class', (d) => 'rect' + d.id)
                .on('mouseover', (d, loc) =>
                    d3.select('.rect'+d.id)
                        .transition().duration(20)
                        .ease('linear')
                        .attr('y',50)
                        .attr('height', 100)
                        .attr('width', 3)
                        .style('fill', 'red')

                    tooltipText = ''
                    d.infoCols.forEach((el) =>
                        tooltipText = tooltipText.concat("<b>"+el.idx+"</b>" + ": " + d[el.idx] + "<br />")
                    )
                    div_right = d3.select('.barcode-div').node().getBoundingClientRect().right
                    #Tooltip width and height
                    tt_left = xScale(x_val(d)) + 25
                    tt_width = 225
                    div.transition(25)
                        .style('opacity', 1)
                        .style('position', 'absolute')
                        .style('min-width', tt_width + 'px')
                        .style('left', if (d3.select('.rect'+d.id).node().getBoundingClientRect().left + tt_width < div_right) then (tt_left) + 'px' else (tt_left - tt_width) + 'px')
                        .style("bottom", (175 + (d.infoCols.length + 1) * 11) + "px")
                    div.html('<span>' + tooltipText+ '</span>')
                    this.dispatch.mouseover(d)
                )
                .on('mouseout', (d, loc) =>
                    d3.select('.rect'+d.id)
                        .transition().duration(100)
                        .ease('linear')
                        .attr('y', 75)
                        .attr('height', 75)
                        .attr('width', 1)
                        .style('fill', 'blue')
                    div.transition(25)
                        .style('opacity', 0)
                )

        # Append Worm
        #Generate worm points
        this.svg.selectAll('path').remove()

        worm_data = this._worm_calc(kept, xdomain)

        lf = d3.svg.line()
            .x((d) => xScale(d.x))
            .y((d) => d.y)
            .interpolate('basis')

        # this.svg.insert('path', 'rect')
        this.svg.append('path')
            .attr('stroke', 'steelblue')
            .attr('fill', 'none')
            .attr("stroke-width", 1.5)
            .attr('d', lf(worm_data))

        # Append background
        #Top & Bottom
        background_top = 110
        background_bottom = 150
        unit_width = xScale(xdomain[1])/5
        left_edge = xScale(xdomain[0])

        _rectPathStr = (left, right, top, bot) ->
            return 'M ' + left + ',' + top + ', L ' + left + ',' + bot + ', L ' + right + ',' + bot + ', L ' + right + ',' + top + ', Z'
        #   red
        this.svg.insert('path', 'rect')
                .style('stroke', 'red')
                .style('fill', 'red')
                .attr('d', _rectPathStr(left_edge, unit_width, background_top, background_bottom))
        #   grey
        this.svg.insert('path', 'rect')
                .style('stroke', 'grey')
                .style('fill', 'grey')
                .attr('d', _rectPathStr(unit_width, unit_width*4, background_top, background_bottom))
        #   blue
        this.svg.insert('path', 'rect')
                .style('stroke', 'blue')
                .style('fill', 'blue')
                .attr('d', _rectPathStr(unit_width*4, unit_width*5, background_top, background_bottom))

    #Need to develp more genesets FIRST
    redraw_double: () ->
        this.redraw_single()

    reFilter: () ->
        if !this.data
            return
        this.redraw()

    update_data: (@data, @barcodeCol, @colouring) ->
        this.redraw()

    on: (t,func) ->
        this.dispatch.on(t, func)

    _worm_calc: (d, domain) ->
        # seq generates n evenly spaced values between -1 and 1
        _seq = (n) ->
            if n <= 1
                return [0]
            val = [0 ... n]
            val.forEach((e, i, arr) =>
                arr[i] = 2 * ((e - arr[0]) / ((arr[arr.length - 1]) - arr[0])) - 1
            )
            val
        # arr - Array to compute moving average
        # wt - Weights for average
        # hw - half the length of weights (floored)
        # w - length of weights (odd)
        _avg = (arr, wt, hw, w) ->
            _calcMean= (arr1, arr2) ->
                if arr1.length != arr2.length
                    console.log(arr1.length)
                    console.log(arr2.length)
                    return -1
                result = Array(arr1.length)
                arr1.forEach((e, i, a) =>
                    result[i] = arr1[i] * arr2[i]
                )
                return result.reduce((a, b) -> a + b)
            #Calculate initial width value
            weighted = Array(arr.length)
            wt_csum = Array(arr.length)
            i = hw
            while i < (arr.length - hw)
                weighted[i] = _calcMean(arr.filter((e, j, a) => (j >= i - hw) && (j <= i + hw)), wt)
                i++

            i = 0
            # Resize the array, removing the padded zeroes
            while i < hw
                weighted.pop()
                weighted.shift()
                i++

            # Produce cumulative sum of weights
            wt.reduce ((a, b, i) ->
                wt_csum[i] = a + b
                ), 0

            # Fix size of array, unclear as to why the length is changed
            wt_csum.splice(wt.length, wt_csum.length)
            i = 0
            # while i < hw
            #     weighted[i] = weighted[i] / wt_csum[(wt_csum.length - i - 1)]
            #     weighted[w - i] = weighted[w - i] / wt_csum[(wt_csum.length - i - 1)]
            #     i++
            return weighted


        all_ranks = [domain[0]...domain[1]]
        #Coerce to list of 1 and 0
        res = all_ranks.map((all_el) => d.map((d_e) => d_e.rank).includes(all_el) + 0)
        slow = false
        if slow
            av = d.length/all_ranks.length
            u = _seq(Math.floor((all_ranks.length * 0.45) / 2) * 2 + 1)
            wt = u.map((e) ->
                Math.pow(Math.pow((1 - Math.abs(e)), 3), 3)
                )
            window_width = u.length
            halfWindow_width = Math.floor(window_width / 2)

            #pad L and R with zeroes
            wk = Array(halfWindow_width).fill(0).concat(res.concat(Array(halfWindow_width).fill(0)))
            avg = _avg(wk, wt, halfWindow_width, window_width)
            avg = avg.map((e, k, a) -> {x: k, y:e})
        else
            av = d.length/all_ranks.length
            avg = res.map((e,k,a) => {x: k, y:(e / av)})
        return avg

    highlight: (d) ->
        _reset = () =>
            this.svg.selectAll('rect')
                .transition().duration(75)
                .ease('linear')
                .attr('y', 75)
                .attr('height', 75)
                .attr('width', 1)
                .style('fill', 'blue')

        if d.length > 0
            _reset()
            d3.select('.rect'+d[0].id)
                .transition().duration(100)
                .ease('linear')
                .attr('y', 50)
                .attr('height', 100)
                .attr('width', 3)
                .style('fill', 'red')

        else
            _reset()

resize = require('./resize-mixin.coffee')

module.exports =
    mixins: [resize]
    props:
        name:
            default: 'barcode'
        marginL:
            default: 30
        marginR:
            default: 30
        marginT:
            default: 30
        marginB:
            default: 30
        plotCols:
            default: null
        data:
            default: null
        filter:
            default: null
        filterChanged: null
        double:
            default: false
        infoCols:
            default: null
        highlight:
            default: null

    computed:
        barcodeCol: () ->
            col = this.plotCols
            # rank by this.plotCols * P value (Close/same as t-statistic)
            this.clone_data.sort((a,b) => a[col[1].idx]*a["P.Value"] - b[col[1].idx]*b["P.Value"])

            this.clone_data.forEach((e,i,a) =>
                e.rank = i
                e.infoCols = this.infoCols
                )
            if col?
                # {name: col[1].name, get: (d) -> d[col[1].idx]}
                {name: col[1].name, get: (d) -> d['rank']}

        needsUpdate: () ->
            this.clone_data
            this.xColumn
            this.yColumn
            this.dimensionScale
            this.colour
            Date.now()

    data: () ->
        clone_data: []

    watch:
        needsUpdate: () ->
            this.update()
        filterChanged: () ->
            this.reFilter()
        highlight: (d) ->
            this.me.highlight(d)

    methods:
        update:() ->
            if this.clone_data? && this.barcodeCol?
                this.me.update_data(this.clone_data,this.barcodeCol,this.colour)
        resize: () ->
            this.$nextTick(() => this.me.resize())
        reFilter: () ->
            this.$emit('keepHighlight', this.clone_data.filter((d) => this.filter(d)), true)
            this.me.reFilter()

    mounted: () ->
        #Clone the data so we can insert a rank ID and InfoCols to the data
        # object. This is potentially slow.
        this.clone_data = JSON.parse(JSON.stringify(this.data))
        this.$emit('keepHighlight', this.clone_data.filter((d) => this.filter(d)), true)
        this.me = new BarcodePlot(
            data: this.clone_data
            elem: this.$refs.barcode
            name: this.name
            colouring: this.colour
            brush_enable: this.brushEnable
            animate: this.animate
            text: this.text
            margin_l: this.marginL
            margin_r: this.marginR
            margin_b: this.marginB
            margin_t: this.marginT
            axis_label_inside: this.axisLabelInside
            filter: this.filter
            double: this.double
            infoCols: this.infoCols
            height: 250
            barcodeCol: this.barcodeCol
        )
        this.me.on('mouseover', (d) => this.$emit('mouseover', d))
        this.update()
</script>



