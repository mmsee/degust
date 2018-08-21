
blue_to_brown = d3.scale.linear()
  .domain([0,0.05,1])
  .range(['brown', "steelblue", "steelblue"])
  .interpolate(d3.interpolateLab)

about = require('./about.vue').default
navbar = require('./navbar.vue').default

backends = require('./backend.coffee')
sliderText = require('./slider.vue').default
conditions = require('./conditions-selector.vue').default
filterGenes = require('./filter-genes.vue').default
extraInfo = require('./extra-info.vue').default
modalExpDesc = require('./modal-ExpDesc.vue').default
ErrorMsg = require('./modal-error-msg.vue').default
Modal = require('modal-vue').default
geneTable = require('./gene-table.vue').default
maPlot = require('./ma-plot.vue').default
volcanoPlot = require('./volcano-plot.vue').default
mdsPlot = require('./mds-plot.vue').default
qcPlots = require('./qc-plots.vue').default
geneStripchart = require('./gene-stripchart.vue').default
parallelCoord = require('./parcoords.vue').default
heatmap = require('./heatmap.vue').default
barcodePlot = require('./barcodeplot.vue').default
{ Normalize } = require('./normalize.coffee')
{ GeneData } = require('./gene_data.coffee')
{ GeneList } = require('./gene_list.coffee')
{ GeneListAPI } = require('./gene_list_api.coffee')

module.exports =
    name: 'compare-single'
    props:
        inputSettings:
            default: () -> {}
        inputCode: null
        navbar:
            default: () -> true
        shown:
            default: true              # Can be useful to allow this to trigger redraws, etc

    components:
        about: about
        navbar: navbar

        sliderText: sliderText
        conditionsSelector: conditions
        filterGenes: filterGenes
        extraInfo: extraInfo
        ErrorMsg: ErrorMsg
        modalExpDesc: modalExpDesc
        Modal: Modal
        geneTable: geneTable
        maPlot: maPlot
        volcanoPlot: volcanoPlot
        mdsPlot: mdsPlot
        qcPlots: qcPlots
        geneStripchart: geneStripchart
        parallelCoord: parallelCoord
        heatmap: heatmap
        barcodePlot: barcodePlot
    data: () ->
        code: null
        settings: {}
        full_settings:
            extra_menu_html: ''
        load_failed: false
        load_success: false
        num_loading: 0
        showCounts: 'no'
        showIntensity: 'no'
        fdrThreshold: 1
        fcThreshold: 0
        fc_relative_i: null
        ma_plot_fc_col_i: null
        fcStepValues:
            Number(x.toFixed(2)) for x in [0..5] by 0.01
        numGenesThreshold: 100
        skipGenesThreshold: 0
        mdsDimension: 1
        normalization: 'cpm'
        normalizationModeration: 10
        normalizationColumns: null
        normalized_data: null
        maxGenes: 0
        mds_2d3d: '2d'
        mdsDimensionScale: 'independent'
        r_code: ''
        dge_method: null
        dge_methods: []
        qc_plots: []
        showGeneList: false
        user_gene_lists_partial: []
        current_gene_list: {}
        current_gene_list_rows: {}
        current_gene_list_cols: {}
        current_gene_list_genes: []
        glUp_full: undefined
        glDown_full: undefined
        sel_conditions: []             # Array of condition names currently selected to compare
        sel_contrast: null             # Contrast if selected.  Hash with name, and columns
        cur_plot: null
        cur_opts: 'options'
        gene_data: new GeneData([],[])
        genes_selected: []              # Selected by "brushing" on one of the plots
        genes_highlight: []             # Gene hover from 'mouseover' of table
        genes_hover: []                 # Genes hover from 'mouseover' of plot
        show_heatmap: true
        heatmap_show_replicates: false
        show_qc: ''
        show_about: false
        show_extraInfo: false
        extraInfo_data: null
        error_msg: null
        show_Error: false
        show_hoverDesc: false
        show_ModalExperimentDesc: false
        descTooltipLoc: [0,0]
        use_gene_filter: false # We probably want this to be true by default.
        stop_hover_heatmap: true
        geneFilterTop: -1
        geneFilterBottom: -1
        geneListAPI: {}
        barcodeOrderCol: 1 #Defaulting to zero means we have selected the column everything is relative to.
        #colour_by_condition: null  # Don't want to track changes to this!

    computed:
        home_link: () -> this.settings?.home_link || '/'
        fdrWarning: () -> this.cur_plot == 'mds' && this.fdrThreshold<1
        fcWarning: () -> this.cur_plot == 'mds' && this.fcThreshold>0
        experimentName: () -> this.settings?.name || "Unnamed"
        can_configure: () ->
            !this.settings.config_locked || this.full_settings.is_owner
        config_url: () -> "config.html?code=#{this.code}"
        gene_data_rows: () ->
            this.gene_data.get_data()
        expr_data: () ->
            console.log "computing expr_data.  orig length=", this.gene_data.get_data().length
            Vue.noTrack(this.gene_data.get_data().filter((v) => this.expr_filter(v)))
        avg_column: () ->
            this.gene_data.columns_by_type('avg')[0]
        fdr_column: () ->
            this.gene_data.columns_by_type('fdr')[0]
        fc_relative: () ->
            if this.fc_relative_i>=0
                this.fc_columns[this.fc_relative_i]
            else
                'avg'
        ma_plot_fc_col: () ->
            this.fc_calc_columns[this.ma_plot_fc_col_i]
        fc_columns: () ->
            this.gene_data.columns_by_type(['fc','primary'])
        fc_calc_columns: () ->
            this.fc_relative     # Listed so to create a dependency.
            this.gene_data.columns_by_type(['fc_calc'])
        info_columns: () ->
            this.gene_data.columns_by_type(['info'])
        count_columns: () ->
            fc_names = this.fc_calc_columns.map((c) -> c.name)
            this.gene_data.columns_by_type('count').filter((c) -> fc_names.indexOf(c.parent)>=0)
        all_columns: () ->
            this.gene_data.columns
        filter_changed: () ->
            this.fdrThreshold
            this.fcThreshold
            this.user_gene_list_cache
            this.use_gene_filter
            this.current_gene_list.title
            Date.now()
        need_renormalization: () ->
            this.normalization
            this.normalizationModeration
            Date.now()
        heatmap_dimensions: () ->
            if (!this.heatmap_show_replicates)
                heatmap_dims = this.gene_data.columns_by_type('fc_calc_avg')
            else
                heatmap_dims = this.normalizationColumns
            heatmap_dims

        #Added to show/hide counts/intensity
        is_pre_analysed: () ->
            this.settings.input_type == 'preanalysed'
        is_rnaseq_counts: () ->
            this.settings.input_type == 'counts'
        is_maxquant: () ->
            this.settings.input_type == 'maxquant'

        tooltipStyleDesc: () ->
            {left: (this.descTooltipLoc[0])+'px', top: (this.descTooltipLoc[1] + window.pageYOffset)+'px'}
            # {left: (this.descTooltipLoc[0])+'px', top: undefined}

        #This does NOT have full genelists. Only has enough to make it searchable.
        user_gene_lists:
            get: () ->
                this.userGeneLists
            set: (val) ->
                this.userGeneLists = val

    watch:
        '$route': (n,o) ->
            this.parse_url_params(n.query)
        settings: () ->
            this.dge_method = this.settings.dge_method || ''
            this.sel_conditions = this.$route.query.sel_conditions || this.settings.init_select || []
            this.$global.asset_base = this.settings?.asset_base || ''

        cur_plot: () ->
            # On plot change, reset brushes
            this.genes_highlight = []
            this.genes_selected = this.gene_data.get_data()
        maxGenes: (val) ->
            this.$refs.num_genes.set_max(this.numGenesThreshold, 1, val, true)
            this.$refs.skip_genes.set_max(this.skipGenesThreshold, 0, val, true)
        fc_relative: () ->
            this.gene_data.set_relative(this.fc_relative)
        experimentName: () ->
            document.title = this.experimentName
        need_renormalization: () ->
            this.renormalize()
        shown: () ->
            this.$emit('resize')
        current_gene_list: (val) ->
            if !val.data?
                current_gene_list_rows: {}
                current_gene_list_cols: {}
                current_gene_list_genes: []
                this.set_genes_selected(this.gene_data.get_data())
            else
                this.current_gene_list_cols = val.get_rows()
                this.current_gene_list_rows = val.get_columns()
                this.set_genes_selected(this.expr_data)
                #No gene list should ever have a length of zero, but still check for it in case
                if this.current_gene_list_rows.length == 0
                    return
                else
                    this.current_gene_list_genes = val.get_members()
        #Watch for changes to genefiltertop/bottom and then update glUp/Down asynchronously
        geneFilterTop: (val) ->
            if val != -1
                this.geneListAPI.get_geneList(this.user_gene_lists_partial[val].id).then((x) =>
                    this.glUp_full = new GeneList(x.title, {rows: JSON.parse(x.rows), columns: JSON.parse(x.columns)}, x.id_type, x.collection_type, x.description)
                )
            else
                this.glUp_full = undefined
        geneFilterBottom: (val) ->
            if val != -1
                this.geneListAPI.get_geneList(this.user_gene_lists_partial[val].id).then((x) =>
                    this.glDown_full = new GeneList(x.title, {rows: JSON.parse(x.rows), columns: JSON.parse(x.columns)}, x.id_type, x.collection_type, x.description)
                )
            else
                this.glDown_full = undefined

    methods:
        init: () ->
            if !this.inputCode? && Object.keys(this.inputSettings).length==0
                log_error("No code, or settings specified")
            else if Object.keys(this.inputSettings).length>0
                # This is used when data is embedded in the html page
                this.load_success=true
                this.settings = this.inputSettings
                this.$nextTick(() -> this.initBackend(false))
            else
                this.code = this.inputCode
                log_info("Loading settings for code : #{this.code}")
                $.ajax({
                    type: "GET",
                    url: backends.BackendCommon.script(this.code,"settings"),
                    dataType: 'json'
                }).done((json) =>
                    this.full_settings = json
                    this.settings = json.settings

                    # Deal with old "analyze_server_side" option
                    if this.settings.analyze_server_side? && !this.settings.input_type?
                        this.settings.input_type = if this.settings.analyze_server_side then 'counts' else 'preanalysed'

                    this.load_success=true
                    this.$nextTick(() -> this.initBackend(true))
                 ).fail((x) =>
                    log_error "Failed to get settings!",x
                    this.load_failed = true
                    this.$nextTick(() ->
                        this.error_msg.msg = x.responseText
                        this.show_Error = true
                    )
                )

        initBackend: (use_backend) ->
            this.ev_backend = new Vue()
            this.ev_backend.$on("start_loading", () => this.num_loading+=1)
            this.ev_backend.$on("done_loading", () => this.num_loading-=1)
            this.ev_backend.$on("errorMsg", (errorMsg) =>
                this.error_msg = errorMsg
                this.show_Error = true
                )
            if !use_backend
                this.backend = new backends.BackendNone(this.settings, this.ev_backend)
            else
                this.geneListAPI = new GeneListAPI(this.code, this.full_settings.tok)
                switch this.settings.input_type
                    when 'counts'
                        this.backend = new backends.BackendRNACounts(this.code, this.settings, this.ev_backend)
                    when 'maxquant'
                        this.backend = new backends.BackendMaxQuant(this.code, this.settings, this.ev_backend)
                    when 'preanalysed'
                        this.backend = new backends.BackendPreAnalysed(this.code, this.settings, this.ev_backend)
                    else
                        log_error("Unknown input_type : ",this.settings.input_type)

                # If we're not configured, redirect to the config page
                if !this.backend.is_configured()
                    window.location = this.config_url
                this.dge_methods = this.backend.dge_methods()
                this.qc_plots = this.backend.qc_plots()

                # If there is no default dge_method set, then use first thing in the list
                if this.dge_methods.length>0 && !this.settings.dge_method?
                    this.dge_method = this.dge_methods[0][0]

            this.request_data()

        # Send a request to the backend.  First request, or when selected samples has changed
        request_data: () ->
            p = this.backend.request_data(this.dge_method, this.sel_conditions, this.sel_contrast)
            p.then(([data,cols,extra]) => this.process_dge_data(data,cols,extra))

        process_dge_data: (data, cols, extra) ->
            this.gene_data = new GeneData(data, cols)
            this.maxGenes = this.gene_data.get_data().length
            this.numGenesThreshold = this.maxGenes
            this.fc_relative_i = 0
            this.ma_plot_fc_col_i = 1
            this.extraInfo_data = extra
            this.set_genes_selected(this.gene_data.get_data())
            this.genes_hover = [this.gene_data.get_data()[0]]
            this.genes_highlight = []
            this.colour_by_condition = if this.fc_columns.length<=10 then d3.scale.category10() else d3.scale.category20()
            if (!this.cur_plot? || this.cur_plot in ["parcoords","ma"])
                this.cur_plot = if this.fc_columns.length>2 then "parcoords" else "ma"
            if this.fc_columns.length==2
                this.heatmap_show_replicates = true
            this.renormalize()
            this.$emit('update', this.gene_data)

        renormalize: () ->
            switch this.normalization
                when 'cpm'
                    cols = Normalize.normalize_cpm(this.gene_data, this.count_columns, this.normalizationModeration)
                    this.normalizationColumns = cols
                when 'backend', 'remove-hidden'
                    this.ev_backend.$emit('start_loading')
                    p = this.backend.request_normalized(this.normalization, this.dge_method, this.sel_conditions, this.sel_contrast)
                    Normalize.normalize_from_backend(this.gene_data, this.count_columns, this.normalization, p).then((new_cols) =>
                        this.normalizationColumns = new_cols
                        this.ev_backend.$emit('done_loading')
                    )

        # Selected samples have changed, request a new dge
        change_samples: (cur) ->
            this.dge_method = cur.dge_method
            this.sel_conditions = cur.sel_conditions
            this.sel_contrast = cur.sel_contrast
            this.request_data()

        set_genes_selected: (d) ->
            this.genes_selected = Vue.noTrack(d)
        set_genes_highlight: (d) ->
            this.genes_highlight = Vue.noTrack(d)

        hover_genes: (d) ->
            this.genes_hover = this.genes_highlight = Vue.noTrack([d])
        stop_hover_genes: () ->
            this.genes_highlight=[]
        gene_table_hover: (d) ->
            this.genes_hover = this.genes_highlight = Vue.noTrack([d])
        gene_table_nohover: () ->
            this.genes_highlight=[]

        # Request and display r-code for current selection
        show_r_code: () ->
            p = this.backend.request_r_code(this.dge_method, this.sel_conditions, this.sel_contrast)
            p.then((d) =>
                this.r_code = d
            )
        close_r_code: () -> this.r_code = ''

        plot_colouring: (d) ->
            blue_to_brown(d[this.fdr_column.idx])
        condition_colouring: (c) ->
            this.colour_by_condition(c)
        fmtPCAText: (v) ->
            v+" vs "+(v+1)
        fdrValidator: (v) ->
            n = Number(v)
            !(isNaN(n) || n<0 || n>1)
        intValidator: (v) ->
             n = Number(v)
             !(isNaN(n) || n<0)
        moderationValidator: (v) ->
            n = Number(v)
            !(isNaN(n) || n<=0)

        # Check if the passed row passes filters for : FDR, FC, Kegg, Filter List
        expr_filter: (row) ->
            #console.log "filter"
            if this.fcThreshold>0
                # Filter using largest FC between any pair of samples
                fc = this.gene_data.columns_by_type('fc').map((c) -> row[c.idx])
                extent_fc = d3.extent(fc.concat([0]))
                if Math.abs(extent_fc[0] - extent_fc[1]) < this.fcThreshold
                    return false

            # Filter by genes in user_gene_list
            if this.current_gene_list.title? #&& this.use_gene_filter
                info_cols = this.gene_data.columns_by_type('info').map((c) -> row[c.idx])
                matching = info_cols.filter((col) =>
                    this.current_gene_list_genes.map((e,i,a) ->
                        e.toLowerCase()).includes(col.toLowerCase()
                    )
                    this.current_gene_list.get_members().map((e) -> e.toLowerCase()).includes(col.toLowerCase())
                )
                if matching.length == 0
                    return false
            # Filter by FDR
            pval_col = this.fdr_column
            return false if row[pval_col.idx] > this.fdrThreshold

            true

        tip: (txt) ->
            {content:txt, placement:'left'}

        hoverExperimentDesc: () ->
            this.show_hoverDesc = true
            locRect = document.getElementById("experimentDescriptionLoc").getBoundingClientRect()
            this.descTooltipLoc = [(locRect.left + locRect.width + 1), locRect.top - 60] #Need to find a better way to set this y-axis location.
            return

        modalExperimentDesc: () ->
            this.show_ModalExperimentDesc = true
            return

        script: (typ) ->
            "#{this.code}/#{typ}"
        # This needs to have some/any feedback upon a(n) (un)successful save
        save: () ->
            # to_send = to_server_model(this.settings)
            $.ajax(
                type: "POST"
                url: this.script("settings")
                data: {settings: JSON.stringify(this.settings)}
                dataType: 'json'
            ).done((x) =>
            ).fail((x) =>
                log_error("ERROR",x)
            )

        download_raw: () ->
            $.ajax(
                type: "GET"
                url: window.location.origin + '/degust/' + this.code + '/' + 'csv'
            ).done((x) =>
                # Generate download link from: https://stackoverflow.com/q/2897619
                pom = document.createElement('a')
                pom.setAttribute('href', 'data:text/plain;charset=utf-8,' + x)
                pom.setAttribute('download', this.settings.name)
                if document.createEvent
                    event = document.createEvent('MouseEvents')
                    event.initEvent('click', true, true)
                    pom.dispatchEvent(event)
                else
                    pom.click()
                    document.body.appendChild(link)
                    pom.remove()
            ).fail((x) =>
                log_error("ERROR", x)
            )

        downloadR: () ->
            rcode = ""
            p = this.backend.request_r_code(this.dge_method, this.sel_conditions, this.sel_contrast)
            p.then((d) =>
                element = document.createElement('a');
                element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(d));
                element.setAttribute('download', "degust.R");
                element.style.display = 'none';
                document.body.appendChild(element);
                element.click();
                document.body.removeChild(element);

            )


    mounted: () ->
        this.init()

        # TODO : ideally just this component, not window.  But, need ResizeObserver to do this nicely
        window.addEventListener('resize', () => this.$emit('resize'))
