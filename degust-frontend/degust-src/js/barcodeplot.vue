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

    div >>> .axis path,
    .axis line {
        fill: none;
        stroke: black;
        shape-rendering: crispEdges;
    }

    .axis text {
        font-family: sans-serif;
        font-size: 11px;
    }
</style>

<template>
    <div>
        <div class='barcode-div' ref='barcode'>
        </div>
        <div class='barcode-tooltip'></div>
        <div class='barcode-tooltip-bottom'></div>
    </div>
</template>

<script lang='coffee'>

css = {axis: 'axis', barcode: 'barcode'}

#Avg function for a web worker
avg = (e) ->
    [arr, hw, w, weights, wormIndex] = e.data
    if !arr?
        self.postMessage({error: "Data missing"})
        return

    if !hw? || !w?
        self.postMessage({error: "Weight lengths missing"})
        return

    if arr? && arr.length==0
        self.postMessage({done: []})
        return

    #Does not avoid NaN/undefined values
    sum = (values) ->
        n = values.length
        i = -1
        total = 0
        while ++i < n
            total += values[i]
        total
    _dot = (arr1, arr2, sumfunc) =>
        total = new Float64Array(arr1.length)
        i = -1
        # end = arr1.length
        while(i++ < arr1.length)
            total[i] = arr1[i] * arr2[i]
        res = sum(total)
        return res

    end = arr.length - hw
    i = hw - 1
    result = new Float64Array(arr.length - hw * 2)
    while (i++ <= end)
        result[i-hw] = _dot(arr.slice(i-hw, i+hw+1), weights.weights)
    # adjust ends
    i = -1
    half_csum = weights.csum.slice(w-hw, w-1)
    end = half_csum.length - 1
    while i++ < end
        result[i] = result[i] / half_csum[i]
        result[end - i] / half_csum[i]

    postMessage({done: result, index: wormIndex})
    close()

#Make barcode plot object
class BarcodePlot
    constructor: (@opts={}) ->
        this.name ?= 'barcode'
        this.opts.xaxis_loc ?= 'zero'
        this.opts.yaxis_loc ?= 'left'
        this.opts.colouring ?= () -> '#61a8ff'
        this.opts.infoCols ?= ''
        this.opts.height ?= 200
        this.data = this.opts.data
        this.barcodeCol = this.opts.barcodeCol

        this.geneListUp = this.opts.geneListUp
        this.geneListDown = this.opts.geneListDown

        this.elem = d3.select(this.opts.elem).append('div')
        # this.elem.attr('class'. css.barcode)

        if this.opts.width
            this.elem.style('width', this.opts.width+'px')
        if this.opts.height
            this.elem.style('height', this.opts.height+'px')

        #Web worker for calculating moving average
        this.worker = [new WorkerWrapper(avg, (d) => this._worker_callback(d)), new WorkerWrapper(avg, (d) => this._worker_callback(d))]
        this.wormVal = {}

        #Initialise SVG's
        # May want to consider using canvas because 11K+ rectangles is a lot
        this.svg = this.elem.append('svg')
        this.gRect = this.svg

        #If brush - Initialise it here - No brush support yet
        this.dispatch = d3.dispatch('mouseover', 'mouseout')
        #This calls the resize which calls the redraw
        this.resize()

    _worker_callback: (d) ->
        if d.error?
            log_error("Worker error : #{d.error}")
        # if d.upto?
        #     this._show_calc_info("Clustered #{d.upto} of #{this.data.length}")
        if d.done?
            this.wormVal['w'+d.index] = {data: d.done, id: if d.index == 1 then Object.keys(this.geneListUp).join() else Object.keys(this.geneListDown).join()}
            # this.wormVal['w'+d.index].data = d.done
            # this.wormVal['w'+d.index].id = 'aaaa'
            this.redraw()
        # if d.took?
        #     log_debug("calc_order: took=#{d.took}ms for #{this.data.length} points")

    resize: () ->
        this.width = this.opts.width || this.elem.node().clientWidth
        this.height = this.opts.height || this.elem.node().clientHeight
        this.svg.attr('width', this.width)
                .attr('height', this.height)
        this.redraw()

    #returns the appropriate redraw function for double/single plots
    redraw: () ->
        this.redraw_single()
        if this.opts.double && Object.keys(this.geneListDown).length > 0
            this.redraw_double()

    redraw_single: () ->
        if !this.data
            return
        this.x_val = x_val = (d) =>
            this.barcodeCol.get(d)

        this.xdomain = xdomain = d3.extent(this.data, (d) => x_val(d)).map((x) => x)

        this.xScale = xScale = d3.scale.linear()
            .domain([0, this.data.length])
            .range([this.opts.margin_l, this.width-this.opts.margin_l-this.opts.margin_r])

        # Kept - stuff that passes filter
        # rect_new - New points to add
        # .exit - Remove old
        # .enter - Add new
        kept = this.data.filter((d) => this.opts.filterFunc(d, this.geneListUp))
        rects = this.svg.selectAll('rect')
                        .data(kept.reverse())

        # Remove ALL old points
        rects.exit().remove()
        this.svg.selectAll('path').remove()
        this.svg.selectAll('g').remove()

        div = d3.select('.barcode-tooltip')

        #Append data
        rects.enter().append('rect')
                .style('fill', '#b0051b')
                .attr('height', 75)
                .attr('width', 1)
                .attr('y', 50)

        #dispatch for hover event
        rects.attr('x',(d) => xScale(x_val(d)))
                .attr('class', (d) => 'rect' + d.id + ' ' + 'up')
                .on('mouseover', (d, loc) =>
                    d3.select('.rect'+d.id)
                        .transition().duration(20)
                        .ease('linear')
                        .attr('y',25)
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
                        .style('left', if (d3.select('.rect'+d.id+'.up').node().getBoundingClientRect().left + tt_width < div_right) then (tt_left) + 'px' else (tt_left - tt_width) + 'px')
                        .style("top", (50) + "px")
                    div.html('<span>' + tooltipText+ '</span>')
                    this.dispatch.mouseover(d)
                )
                .on('mouseout', (d, loc) =>
                    d3.select('.rect'+d.id+'.up')
                        .transition().duration(100)
                        .ease('linear')
                        .attr('height', 75)
                        .attr('width', 1)
                        .attr('y', 50)
                        .style('fill', '#b0051b')
                    div.transition(25)
                        .style('opacity', 0)

                    d3.select('.rect'+d.id+'.down')
                        .transition().duration(100)
                        .ease('linear')
                        .attr('y', 125)
                        .attr('height', 75)
                        .attr('width', 1)
                        .style('fill', '#0571b0')
                )

        # Insert Background
        #Top & Bottom
        background_top = 90
        background_bottom = 125
        # unit_width = xScale(xdomain[1])/5
        # left_edge = xScale(xdomain[0])

        rank_ordering = this.data.map((e) -> e.sign)
        #Find first value
        right_val = rank_ordering.indexOf(rank_ordering.find((e) -> e > Math.SQRT2))
        #Find last value
        left_val = rank_ordering.indexOf(rank_ordering.filter((e) -> e < (-1 * Math.SQRT2)).pop())

        _rectPathStr = (left, right, top, bot) ->
            return 'M ' + left + ',' + top + ', L ' + left + ',' + bot + ', L ' + right + ',' + bot + ', L ' + right + ',' + top + ', Z'
        #   red
        this.svg.insert('path', 'rect')
                .style('stroke', '#ff6961')
                .style('fill', '#ff6961')
                .attr('d', _rectPathStr(xScale(xdomain[0]), xScale(left_val), background_top, background_bottom))
        #   grey
        this.svg.insert('path', 'rect')
                .style('stroke', 'adadad')
                .style('fill', 'adadad')
                .attr('d', _rectPathStr(xScale(left_val), xScale(right_val), background_top, background_bottom))
        #   blue
        this.svg.insert('path', 'rect')
                .style('stroke', '#61a8ff')
                .style('fill', '#61a8ff')
                .attr('d', _rectPathStr(xScale(right_val), xScale(xdomain[1]), background_top, background_bottom))

        # Append Worm
        #Generate worm points
        if this.wormVal.w1? && (this.wormVal.w1.id == this.curW1)
            worm_data = Array.prototype.slice.call(this.wormVal.w1.data).map((e, k, a) -> {x: k, y:e})
            avg = kept.length / this.data.length
            avg_data = worm_data.map((e) -> {x: e.x, y: avg})
            yScale1Extent = [d3.extent(worm_data.map((e) -> e.y))[1], 0]
            this.yScale = yScale = d3.scale.linear()
                .domain(yScale1Extent)
                .range([this.opts.margin_t, this.height * 0.35])

            yaxis = d3.svg.axis()
                    .scale(yScale)
                    .orient('left')
                    .tickValues([0,yScale1Extent[0]/2,yScale1Extent[0]])

            this.svg.append('g')
                .attr('class', 'axis')
                .attr('transform', 'translate('+this.opts.margin_l+',0)')
                .call(yaxis)

            lf = d3.svg.line()
                .x((d) => xScale(d.x))
                .y((d) => yScale(d.y))
                .interpolate('basis')

            # this.svg.insert('path', 'rect')
            this.svg.append('path')
                .attr('stroke', '#970417')
                .attr('fill', 'none')
                .attr("stroke-width", 2)
                .attr('d', lf(worm_data))

            # Add median/mean graph of values
            this.svg.append('path')
                .attr('stroke', 'black')
                .attr('fill', 'none')
                .attr("stroke-width", 1.5)
                .style("stroke-dasharray", "4,4")
                .attr('d', lf(avg_data))
            # this.wormVal.w1 = undefined
        else
            this._worm_calc(kept, xdomain, this.worker[0], 1)

    #Need to develp more genesets FIRST
    redraw_double: () ->
        keptDown = this.data.filter((d) => this.opts.filterFunc(d, this.geneListDown))
        div = d3.select('.barcode-tooltip-bottom')

        rectsDown = this.svg.selectAll('.rect.down')
                            .data(keptDown.reverse())
        rectsDown.exit().remove()
        rectsDown.enter().append('rect')
                .style('fill', '#0571b0')
                .attr('height', 75)
                .attr('width', 1)
                .attr('y', 125)

        rectsDown.attr('x',(d) => this.xScale(this.x_val(d)))
                .attr('class', (d) => 'rect' + d.id + ' ' + 'down')
                .on('mouseover', (d, loc) =>
                    d3.select('.rect.down'+d.id)
                        .transition().duration(20)
                        .ease('linear')
                        .attr('y',125)
                        .attr('height', 100)
                        .attr('width', 3)
                        .style('fill', 'red')

                    tooltipText = ''
                    d.infoCols.forEach((el) =>
                        tooltipText = tooltipText.concat("<b>"+el.idx+"</b>" + ": " + d[el.idx] + "<br />")
                    )
                    div_right = d3.select('.barcode-div').node().getBoundingClientRect().right
                    #Tooltip width and height
                    tt_left = this.xScale(this.x_val(d)) + 25
                    tt_width = 225
                    div.transition(25)
                        .style('opacity', 1)
                        .style('position', 'absolute')
                        .style('min-width', tt_width + 'px')
                        .style('left', if (d3.select('.rect'+d.id+".down").node().getBoundingClientRect().left + tt_width < div_right) then (tt_left) + 'px' else (tt_left - tt_width) + 'px')
                        .style("bottom", (0 + (d.infoCols.length + 1) * 11) + "px")
                    div.html('<span>' + tooltipText+ '</span>')
                    this.dispatch.mouseover(d)
                )
                .on('mouseout', (d, loc) =>
                    d3.select('.rect'+d.id+'.down')
                        .transition().duration(100)
                        .ease('linear')
                        .attr('height', 75)
                        .attr('width', 1)
                        .attr('y', 125)
                        .style('fill', '#0571b0')
                    div.transition(25)
                        .style('opacity', 0)

                    d3.select('.rect'+d.id+'.up')
                        .transition().duration(100)
                        .ease('linear')
                        .attr('y', 50)
                        .attr('height', 75)
                        .attr('width', 1)
                        .style('fill', '#b0051b')
                )

        background_top = 125
        background_bottom = 160
        rank_ordering = this.data.map((e) -> e.sign)
        #Find first value
        right_val = rank_ordering.indexOf(rank_ordering.find((e) -> e > Math.SQRT2))
        #Find last value
        left_val = rank_ordering.indexOf(rank_ordering.filter((e) -> e < (-1 * Math.SQRT2)).pop())

        _rectPathStr = (left, right, top, bot) ->
            return 'M ' + left + ',' + top + ', L ' + left + ',' + bot + ', L ' + right + ',' + bot + ', L ' + right + ',' + top + ', Z'
        #   red
        this.svg.insert('path', 'rect')
                .style('stroke', '#ff6961')
                .style('fill', '#ff6961')
                .attr('d', _rectPathStr(this.xScale(this.xdomain[0]), this.xScale(left_val), background_top, background_bottom))
        #   grey
        this.svg.insert('path', 'rect')
                .style('stroke', 'adadad')
                .style('fill', 'adadad')
                .attr('d', _rectPathStr(this.xScale(left_val), this.xScale(right_val), background_top, background_bottom))
        #   blue
        this.svg.insert('path', 'rect')
                .style('stroke', '#61a8ff')
                .style('fill', '#61a8ff')
                .attr('d', _rectPathStr(this.xScale(right_val), this.xScale(this.xdomain[1]), background_top, background_bottom))

        # Append Worm
        #Generate worm points
        if this.wormVal.w2? && (this.wormVal.w2.id == this.curW2)
            worm_data = Array.prototype.slice.call(this.wormVal.w2.data).map((e, k, a) -> {x: k, y:e})
            avg = keptDown.length / this.data.length
            avg_data = worm_data.map((e) -> {x: e.x, y: avg})

            yScale2Extent = [0, d3.extent(worm_data.map((e) -> e.y))[1]]

            this.yScale2 = yScale2 = d3.scale.linear()
                .domain(yScale2Extent)
                .range([this.height * 0.65, this.height - this.opts.margin_b])

            yaxis2 = d3.svg.axis()
                    .scale(this.yScale2)
                    .orient('left')
                    .tickValues([0,yScale2Extent[1]/2,yScale2Extent[1]])

            this.svg.append('g')
                .attr('class', 'axis')
                .attr('transform', 'translate('+this.opts.margin_l+',0)')
                .call(yaxis2)

            lf = d3.svg.line()
                .x((d) => this.xScale(d.x))
                .y((d) => this.yScale2(d.y))
                .interpolate('basis')

            # this.svg.insert('path', 'rect')
            this.svg.append('path')
                .attr('stroke', '#04517e')
                .attr('fill', 'none')
                .attr("stroke-width", 2)
                .attr('d', lf(worm_data))

            # Add median/mean graph of values
            this.svg.append('path')
                .attr('stroke', 'black')
                .attr('fill', 'none')
                .attr("stroke-width", 1.5)
                .style("stroke-dasharray", "4,4")
                .attr('d', lf(avg_data))
            # this.wormVal.w2 = undefined
        else
            this._worm_calc(keptDown, this.xdomain, this.worker[1], 2)


    reFilter: () ->
        if !this.data
            return
        this.redraw()

    update_data: (data, barcodeCol, geneListUp, geneListDown) ->
        this.data = data
        this.barcodeCol = barcodeCol
        this.geneListUp = geneListUp
        this.geneListDown = geneListDown
        this.curW1 = Object.keys(geneListUp).join()
        this.curW2 = Object.keys(geneListDown).join()
        this.redraw()

    on: (t,func) ->
        this.dispatch.on(t, func)

    _worm_calc: (d, domain, worker, wormIndex) ->
        _weights = (n) ->
            if n <= 1
                return [0]
            val = new Float64Array([0 ... n])
            i = -1
            end = val.length
            while(i++ < end)
                val[i] = 1 - Math.abs(2 * ((val[i]) / (val[n - 1])) - 1) ** 3

            total = val.reduce((a,b) -> a+b)
            csum = new Float64Array(n)
            val[0] = val[0] / total

            #Catch first/last == 0
            end = val.length - 1
            if val[0] == 0
                val[0] = val[val.length-1] = (val[1] / 2) / total
            csum[0] = val[0]
            i = 0
            while(i++ <= end)
                val[i] = val[i] / total
                csum[i] = val[i] + csum[i-1]

            {weights: val, csum: csum}
        _avg = (arr, hw, w, wormIndex, worker) ->
            #call web worker
            worker.start([arr, hw, w, _weights(w), wormIndex])

        all_ranks = [domain[0]...domain[1]]
        #Coerce to list of 1 and 0
        res = all_ranks.map((all_el) => d.map((d_e) => d_e.rank).includes(all_el) + 0)

        hav = d.length/all_ranks.length
        #pad L and R with zeroes
        window_width = Math.floor((all_ranks.length * 0.45) / 2) * 2 + 1
        halfWindow_width = Math.floor(window_width / 2)

        # Pad out ends of array with mean of halfwidth to reduce artefact of having padded with zeroes
        wk = Array(halfWindow_width).fill(0).concat(res.concat(Array(halfWindow_width + 1).fill(0)))

        avg = _avg(wk, halfWindow_width, window_width, wormIndex, worker)

    highlight: (d) ->
        _reset = () =>
            this.svg.selectAll('rect')
                .transition().duration(75)
                .ease('linear')
                .attr('width', 1)
            this.svg.selectAll('rect.up')
                .style('fill', '#b0051b')
                .attr('height', 75)
                .attr('y', 50)

            this.svg.selectAll('rect.down')
                .style('fill', '#0571b0')
                .attr('height', 75)
                .attr('y', 125)


        if d.length > 0
            _reset()
            d3.select('.rect'+d[0].id+'.up')
                .transition().duration(100)
                .ease('linear')
                .attr('y', 25)
                .attr('height', 100)
                .attr('width', 3)
                .style('fill', 'red')

            d3.select('.rect'+d[0].id+'.down')
                .transition().duration(100)
                .ease('linear')
                .attr('y',125)
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
            default: 40
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
        filterUp:
            default: null
        filterDown:
            default: null
        filterExt:
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
            this.clone_data.forEach((e) ->
                e.sign = Math.sign(e[col[1].idx]) * Math.log2(e["P.Value"])
            )
            this.clone_data.sort((a,b) =>
               a.sign - b.sign
            )
            this.clone_data.forEach((e,i,a) =>
                e.rank = i
                e.infoCols = this.infoCols
                )
            if col?
                # {name: col[1].name, get: (d) -> d[col[1].idx]}
                {name: col[1].name, get: (d) -> d['rank']}

        needsUpdate: () ->
            this.clone_data
            # this.dimensionScale
            # this.colour
            this.filterUp
            this.filterDown
            Date.now()

        glUp: () ->
            genelist = this.filterUp
            res = {}
            if !genelist?
                return res
            genelist.get_members().forEach((val) -> res[val] = val)
            return res

        glDown: () ->
            genelist = this.filterDown
            res = {}
            if !genelist?
                return res
            genelist.get_members().forEach((val) -> res[val] = val)
            return res

    data: () ->
        clone_data: []

    watch:
        needsUpdate: () ->
            this.update()
        # filterChanged: () ->
        #     this.reFilter()
        highlight: (d) ->
            this.me.highlight(d)

    methods:
        update:() ->
            if this.clone_data? && this.barcodeCol?
                this.me.update_data(this.clone_data,this.barcodeCol,this.glUp,this.glDown)
        resize: () ->
            this.$nextTick(() => this.me.resize())
        # reFilter: () ->
        #     this.$emit('keepHighlight', this.clone_data.filter((d) => this.filter(d)), true)
        #     this.me.reFilter()

        simple_filter:(row, gl) ->
            # Filter by genes in gl
            gl = gl || null
            if !gl?
                return false
            info_cols = this.infoCols.map((c) -> row[c.idx])
            matching = info_cols.filter((col) =>
                col.toLowerCase() of gl
            )
            if matching.length == 0
                return false
            return true

    mounted: () ->
        #Clone the data so we can insert a rank ID and InfoCols to the data
        # object. This is potentially slow.
        this.clone_data = JSON.parse(JSON.stringify(this.data))
        # this.$emit('keepHighlight', this.clone_data.filter((d) => this.filterExt(d)), true)
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
            filter: this.filterExt
            geneListUp: this.glUp
            geneListDown: this.glDown
            filterFunc: this.simple_filter
            double: this.double
            infoCols: this.infoCols
            height: 250
            barcodeCol: this.barcodeCol
        )
        this.me.on('mouseover', (d) => this.$emit('mouseover', d))
        # this.update()
</script>
