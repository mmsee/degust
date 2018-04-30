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
</style>

<template>
    <div class='barcode-div' ref='barcode'>

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

        #This calls the resize which calls the redraw
        this.resize()

    resize: () ->
        this.width = this.opts.width || this.elem.node().clientWidth
        this.height = this.opts.height || this.elem.node().clientHeight
        this.svg.attr('width', this.width)
                .attr('height', this.height)

        this.redraw()

    redraw: () ->
        if !this.data
            return

        this.x_val = x_val = (d) => this.barcodeCol.get(d)

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
        rects = this.svg.selectAll('.rect')
                        .data(kept.reverse())

        rects.exit().remove()

        rect_new = rects.enter().append("g")
            .attr('class', 'rect')

            rect_new.append('rect')
                .attr('x',(d) => xScale(x_val(d)))
                .attr('y', 0)
                .style('fill', 'blue')
                .attr('height', 90)
                .attr('width', 1)

        rects.select('rect')
            .attr('height', 90)
            .attr('width', 1)

    reFilter: () ->
        if !this.data
            return
        console.log("Refiltering")
        this.redraw()

    update_data: (@data, @barcodeCol, @colouring) ->
        this.redraw()

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


    computed:
        barcodeCol: () ->
            col = this.plotCols
            # rank by this.plotCols * P value (Close/same as t-statistic)
            this.data.sort((a,b) => a[col[1].idx]*a["P.Value"] - b[col[1].idx]*b["P.Value"])
            # this.data.sort((a,b) => a[col[1].idx] - b[col[1].idx])

            this.data.forEach((e,i,a) -> e.rank = i)
            if col?
                # {name: col[1].name, get: (d) -> d[col[1].idx]}
                {name: col[1].name, get: (d) -> d['rank']}

        needsUpdate: () ->
            this.data
            this.xColumn
            this.yColumn
            this.dimensionScale
            this.colour
            Date.now()

    # data: () ->

    watch:
        needsUpdate: () ->
            this.update()
        filterChanged: () ->
            console.log('filter changed')
            this.reFilter()

    methods:
        update:() ->
            if this.data? && this.barcodeCol?
                this.me.update_data(this.data,this.barcodeCol,this.colour)
        resize: () ->
            this.$nextTick(() => this.me.resize())
        reFilter: () ->
            this.me.reFilter()

    mounted: () ->
        this.me = new BarcodePlot(
            elem: this.$refs.barcode
            name: this.name
            colouring: this.colour
            filter: this.filter
            brush_enable: this.brushEnable
            animate: this.animate
            text: this.text
            margin_l: this.marginL
            margin_r: this.marginR
            margin_b: this.marginB
            margin_t: this.marginT
            axis_label_inside: this.axisLabelInside
            filter: this.filter
        )
        this.update()
</script>



