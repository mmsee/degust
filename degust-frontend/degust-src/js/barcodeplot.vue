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
        <div class='barcode-tooltip up'></div>
        <div class='barcode-tooltip down'></div>
    </div>
</template>

<script lang='coffee'>

css = {axis: 'axis', barcode: 'barcode'}

#Avg function for a web worker
calc_average = (e) ->
    [arr, hw, w, weights, dir, format] = e.data
    if !arr?
        self.postMessage({error: "Data missing"})
        return

    if !hw? || !w?
        self.postMessage({error: "Weight lengths missing"})
        return

    if arr? && arr.length==0
        self.postMessage({done: []})
        return

    _dot = (arr1, arr2) =>
        total = new Float64Array(arr1.length)
        i = -1
        while(i++ < arr1.length)
            total[i] = arr1[i] * arr2[i]
        res = total.reduce((a,b) -> a + b)
        return res

    end = (arr.length - hw)
    i = hw
    result = new Float64Array(arr.length - hw * 2)
    while (i <= end)
        result[i-hw] = _dot(arr.slice(i-hw, i+hw+1), weights.weights)
        i++

    # Scale tails to moderate padded zeroes from mean.
    i = 0
    half_csum = weights.csum.slice(w-hw, w-1)
    end = hw - 1
    while(i < end)
        result[i] = result[i] / half_csum[i]
        zzz = result[result.length - 1 - i] / half_csum[i]
        result[result.length - 1 - i] = zzz
        i++
    postMessage({done:result, dir:dir, format:format})
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

        # Initialise width and height
        this.width = this.opts.width || this.elem.node().clientWidth
        this.height = this.opts.height || this.elem.node().clientHeight
        this.elem.style('width', this.width+'px')
        this.elem.style('height', this.height+'px')

        #Web worker for calculating moving average
        this.worker = {Up:new WorkerWrapper(calc_average, (d) => this._worker_callback(d)), Down:new WorkerWrapper(calc_average, (d) => this._worker_callback(d))}
        this.wormVal = {}

        #Initialise SVG's
        # May want to consider using canvas because 11K+ rectangles is a lot
        this.svg = this.elem.append('svg')
        this.gRect = this.svg
        this.svg.attr('width', this.width)
                .attr('height', this.height)

        #If brush - Initialise it here - No brush support yet
        this.dispatch = d3.dispatch('mouseover', 'mouseout')
        #This calls the resize which calls the redraw
        #Also sets the size correctly. Calling redraw directly, it would fail.
        this.resize()

    _worker_callback: (d) ->
        if d.error?
            log_error("Worker error : #{d.error}")
        # if d.upto?
        #     this._draw_worm(d.upto, d.dir, d.format, d.i)
        if d.done?
            this._draw_worm(d.done, d.dir, d.format)

    resize: () ->
        this.width = this.opts.width || this.elem.node().clientWidth
        this.height = this.opts.height || this.elem.node().clientHeight
        this.svg.attr('width', this.width)
                .attr('height', this.height)
        this.redraw()

    #returns the appropriate redraw function for double/single plots
    redraw: () ->
        # Setup various heights for each of the two plots
        bDUp = {dir:'Up', y_top:50, r_height:75, r_highlight_top:25, r_highlight_height:100, b_top:90, b_bottom:125, tt_height:50, colour:'#b0051b'}
        bDDown = {dir:'Down', y_top:125, r_height:75, r_highlight_top:125, r_highlight_height:100, b_top:125, b_bottom:160, tt_height:275, colour:'#0571b0'}

        # Always draw one, if second is selected, draw second if we don't want to enable the drawing of the second, don't make a second select for geneListDown
        # Need to find a way to ONLY redraw upon selection of a change and not loop itself.
        # if plot first
        this._redraw_single(this.data, bDUp)
        if Object.keys(this.geneListDown).length > 0 # && plot second
            this._redraw_single(this.data, bDDown)

    _redraw_single: (data, format) ->
        {dir, y_top, r_height, r_highlight_top, r_highlight_height, b_top, b_bottom, tt_height, colour} = format
        if !data
            console.log("No data provided to Barcode plot")
            return

        # Define funciton to get x values from barcode col
        x_val = (d) =>
            this.barcodeCol.get(d)

        # define a x-domain
        xDomain = d3.extent(data, (d) => x_val(d)).map((x) => x)

        this.xScale = xScale = d3.scale.linear()
            .domain([0, this.data.length])
            .range([this.opts.margin_l, this.width-this.opts.margin_l-this.opts.margin_r])

        # Kept - stuff that passes filter
        # rect_new - New points to add
        # .exit - Remove old
        # .enter - Add new
        kept = this.data.filter((d) => this.opts.filterFunc(d, this['geneList'+dir])) # Future refactor may miss this
        rects = this.svg.selectAll('rect'+'.'+dir)
                        .data(kept.reverse())
        # Remove ALL old points
        rects.exit().remove()
        this.svg.selectAll('path'+'.'+dir).remove()
        this.svg.selectAll('g').remove()

        div = d3.select('.barcode-tooltip'+'.'+dir)

        #Append data
        rects.enter().append('rect')
                .style('fill', colour)
                .attr('class', dir)
                .attr('height', r_height)
                .attr('width', 1)
                .attr('y', y_top)

        rank_ordering = data.map((e) -> e.sign)
        #Find first value
        right_val = rank_ordering.indexOf(rank_ordering.find((e) -> e > Math.SQRT2))
        #Find last value
        left_val = rank_ordering.indexOf(rank_ordering.filter((e) -> e < (-1 * Math.SQRT2)).pop())
        _rectPathStr = (left, right, top, bot) ->
            return 'M ' + left + ',' + top + ', L ' + left + ',' + bot + ', L ' + right + ',' + bot + ', L ' + right + ',' + top + ', Z'
        #   red
        this.svg.insert('path', 'rect')
                .attr('class', dir)
                .style('stroke', '#ff6961')
                .style('fill', '#ff6961')
                .attr('d', _rectPathStr(this.xScale(xDomain[0]), this.xScale(left_val), b_top, b_bottom))
        #   grey
        this.svg.insert('path', 'rect')
                .attr('class', dir)
                .style('stroke', 'adadad')
                .style('fill', 'adadad')
                .attr('d', _rectPathStr(this.xScale(left_val), this.xScale(right_val), b_top, b_bottom))
        #   blue
        this.svg.insert('path', 'rect')
                .attr('class', dir)
                .style('stroke', '#61a8ff')
                .style('fill', '#61a8ff')
                .attr('d', _rectPathStr(this.xScale(right_val), this.xScale(xDomain[1]), b_top, b_bottom))

        #dispatch for hover event
        rects.attr('x',(d) => xScale(x_val(d)))
                .attr('class', (d) => 'rect' + d.id + ' ' + dir)
                .on('mouseover', (d, loc) =>
                    d3.select('.rect' + d.id + '.'+dir)
                        .transition().duration(20)
                        .ease('linear')
                        .attr('y',r_highlight_top)
                        .attr('height', r_highlight_height)
                        .attr('width', 3)
                        .style('fill', 'red')

                    #this.svg.append other opposite rect if exists?

                    tooltipText = ''
                    d.infoCols.forEach((el) =>
                        tooltipText = tooltipText.concat("<b>"+el.idx+"</b>" + ": " + d[el.idx] + "<br/>")
                    )
                    div_right = d3.select('.barcode-div').node().getBoundingClientRect().right
                    #Tooltip width and height
                    tt_left = xScale(x_val(d)) + 25
                    tt_width = 225
                    div.transition(25)
                        .style('opacity', 1)
                        .style('position', 'absolute')
                        .style('min-width', tt_width + 'px')
                        .style('left', if (d3.select('.rect'+d.id+'.'+dir).node().getBoundingClientRect().left + tt_width < div_right) then (tt_left) + 'px' else (tt_left - tt_width) + 'px')
                        .style("top", (tt_height) + "px")
                    div.html('<span>' + tooltipText + '</span>')
                    this.dispatch.mouseover(d)
                )
                .on('mouseout', (d, loc) =>
                    d3.select('.rect' + d.id + '.'+dir)
                        .transition().duration(100)
                        .ease('linear')
                        .attr('height', r_height)
                        .attr('width', 1)
                        .attr('y', y_top)
                        .style('fill', colour)
                    div.transition(25)
                        .style('opacity', 0)

                    # d3.select('.rect'+d.id+'.down')
                    #     .transition().duration(100)
                    #     .ease('linear')
                    #     .attr('y', 125)
                    #     .attr('height', 75)
                    #     .attr('width', 1)
                    #     .style('fill', '#0571b0')
                )

        # Add worm somehow.
        # Calculate worm first?
        # Then horizontal line?
        #Get vector of 1/0's
        #Pass to function which produces the appropriate data and await?
        #Just fire it here. Have separate function to draw.

        # this.svg.selectAll('.worm').remove()

        this._calc_worm(kept, xDomain, this.worker[dir], dir, format)

    _calc_worm: (d, domain, worker, dir, format) ->
        #Weight of last value looks like it's too small
        #csum typically > 1 appears like it might be floating point error?
        #If we generate half the weights, then reverse it and append it's 100% symmetrical?
        _weights = (n) ->
            if n <= 1
                return [0]
            wt = new Float64Array(n)
            csum = new Float64Array(n)
            i = -1
            j = 1
            h_len_ceil = Math.ceil(n/2)
            h_len_floor = Math.floor(n/2)
            squeeze = n / (n + 1)
            while(i++ <= n)
                wt[i] = ( (j - h_len_ceil) / h_len_floor ) * squeeze
                wt[i] = (1 - Math.abs(wt[i]) ** 3) ** 3
                j++
            # Scale down to correct size
            #
            wt_total = wt.reduce((a,b) -> a + b)
            wt.forEach((e,i,a) -> a[i] = e / wt_total)
            # Initialise csum
            csum[0] = wt[0]
            i = 1
            while(i++ < n)
                csum[i] = csum[i - 1] + wt[i]

            {weights: wt, csum: csum}
        _avg = (arr, hw, w, dir, format, worker) ->
            #call web worker
            worker.start([arr, hw, w, _weights(w), dir, format])

        all_ranks = [domain[0]..domain[1]]

        res = all_ranks.map((all_el) => d.map((d_e) => d_e.rank).includes(all_el) + 0)
        hav = d.length/all_ranks.length
        #Ensure window is odd in length
        window_width = Math.floor((all_ranks.length * 0.45) / 2) * 2 + 1
        halfWindow_width = Math.floor(window_width / 2)
        # Pad out ends of array with mean of halfwidth to reduce artefact of having padded with zeroes
        wk = Array(halfWindow_width).fill(0).concat(res.concat(Array(halfWindow_width).fill(0)))
        avg = _avg(wk, halfWindow_width, window_width, dir, format, worker)

    _draw_worm: (worm_data, dir, format) ->
        worm_data_obj = Array.prototype.slice.call(worm_data).map((e, k, a) -> {x: k, y:e})
        avg = d3.mean(worm_data)
        avg_data = worm_data_obj.map((e) -> {x: e.x, y: avg}) #This is probably totally unecessary for this.

        scale_format = {Up : [this.opts.margin_t, this.height * 0.35], Down:[this.height * 0.65, this.height - this.opts.margin_b]}
        yScale_extent = {Up: [d3.max(worm_data), 0], Down:[0, d3.max(worm_data)]}
        cols = {Up:'#970417', Down:'#04517e'}

        #Append axis
        yScale = d3.scale.linear()
            .domain(yScale_extent[dir])
            .range(scale_format[dir])

        yaxis = d3.svg.axis()
                .scale(yScale)
                .orient('left')
                .tickValues([0, d3.max(worm_data)/2, d3.max(worm_data)])

        this.svg.selectAll('.worm.'+dir).remove()

        this.svg.append('g')
                .attr('class', 'axis worm '+dir)
                .attr('transform', 'translate('+this.opts.margin_l+',0)')
                .call(yaxis)

        #xScale comes from global scope
        lf = d3.svg.line()
            .x((d) => this.xScale(d.x))
            .y((d) => yScale(d.y))
            .interpolate('basis')

        # this.svg.insert('path', 'rect')
        this.svg.append('path')
            .attr('class', 'path worm '+dir)
            .attr('stroke', cols[dir])
            .attr('fill', 'none')
            .attr("stroke-width", 2)
            .attr('d', lf(worm_data_obj))

        # Add median/mean graph of values
        this.svg.append('path')
            .attr('class', 'path worm '+dir)
            .attr('stroke', 'black')
            .attr('fill', 'none')
            .attr("stroke-width", 1.5)
            .style("stroke-dasharray", "4,4")
            .attr('d', lf(avg_data))

    update_data: (data, barcodeCol, geneListUp, geneListDown) ->
        this.data = data
        this.barcodeCol = barcodeCol
        this.geneListUp = geneListUp
        this.geneListDown = geneListDown
        # this.curW1 = Object.keys(geneListUp).join()
        # this.curW2 = Object.keys(geneListDown).join()
        this.redraw()

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

        # highlight: (d) ->
        #     this.me.highlight(d)

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
                col.toLowerCase() of gl || col of gl
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
        # this.me.on('mouseover', (d) => this.$emit('mouseover', d))
        # this.update()
</script>
