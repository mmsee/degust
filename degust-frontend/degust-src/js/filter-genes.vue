<style scoped>
    #gene-filter-modal >>> .modal-content {
        width: 150%;
        margin-left: -25%;
    }

    .tableWrap {
        width: 100%
    }

    .tableScroll {
        height: 50%;
        overflow: auto;
        margin-top: 20px;
    }

    .userListTable {
        font-family: arial, sans-serif;
        font-size: 8pt;
        border-collapse: collapse;
        overflow-x: auto;
        overflow-y: auto;
        table-layout: fixed;
    }

    .userListTable td, th {
        border: 1px solid #dddddd;
        text-align: left;
        padding: 10px;
    }

    .userListTable button {
        color: #bbbbbb;
        background-color: transparent;
        padding: 0%;
    }

    .userListTable .selected {
        border: 1px solid #000000;
        color: #00aaff;
        font-weight: bolder;
        background-color: #eeeeee;
    }

    .userListTable button:hover {
        color: #e3233a;
    }

    #displaydiv {
        height: 400px;
        overflow-y: scroll;
        /* background-color: lightgrey; */
        border-style: none inset inset none;
        border-width: 2px;
    }

    ::-webkit-scrollbar {
        -webkit-appearance: none;
        width: 7px;
    }
    ::-webkit-scrollbar-thumb {
        border-radius: 4px;
        background-color: rgba(0, 0, 0, .5);
        -webkit-box-shadow: 0 0 1px rgba(255, 255, 255, .5);
    }

</style>

<template>
    <div>
        <meta charset="utf-8">
        <!-- Apply custom background styling conditionally so that nested modals don't change background opacity-->
        <modal
            :showModal='show'
            :closeAction='close'
            id='gene-filter-modal'
            >
            <h4 slot='header'>{{ usingList? (geneLists.length == 0? 'No lists entered' :'Using: ' + curTitle) : 'Gene list filtering toggled off' }}</h4>
            <div slot='body'>
                <div class='row'>
                    <div class='col-xs-8'>
                        <div class='tableWrap'>
                            <ul class="nav nav-tabs">
                                <li :class='{active: cur_tab_left=="user"}'>
                                    <a @click='cur_tab_left="user";'>Your Gene Lists</a>
                                </li>
                            </ul>
                            <br/>
                            <div id='glSearchBox'><input type='text' placeholder="Search..." v-model="searchTerm" style='padding:2px;'></div>
                            <div v-if='cur_tab_left=="user"' class='tableScroll'>
                                <table class='userListTable'>
                                    <tr :key='index' v-for='(list, index) in searchedLists' v-bind:class='{"selected": (index == curList)}'>
                                        <td @click='selectList(index, "user"), user_sel = index'>{{ list.title }}</td>
                                        <td class='removeList'><button type="button" class="btn btn-danger-outline" @click='removeIdx(index)'><span class='glyphicon glyphicon-minus'></span></button></td>
                                    </tr>
                                </table>
                            </div>
                        </div>
                    </div>
                    <div class='col-xs-4' style="">
                        <!-- Need to vertically wrap this div so it can scroll -->
                        <div style='padding-top:35px;'></div>
                        <div style="height:56%;overflow:auto;">
                            <div class='displaydiv' v-if='geneLists.length > 0 && curList != -1'>
                                <h6>Contents of selected gene list</h6>
                                <div :key='idx' v-for='(gene, idx) in curListContents'>{{ gene.id }}</div>
                            </div>
                            <div v-else>
                                <h5>No list Selected</h5>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div slot='footer'>
                <button class="btn btn-success" @click='showAddGenes=true'>Add a gene list</button>
                <button class='btn btn-primary' @click='closeButton'>Save & Close</button>
            </div>
        </modal>

        <addGeneListModal
            style="z-index: 2"
            :showAddList='showAddGenes'
            :allGeneTitles='geneLists.map(e => e.title)'
            @geneset='(list) => appendToList(list)'
            @close='showAddGenes=false'>
        </addGeneListModal>

    </div>
</template>

<script lang='coffee'>

Modal = require('modal-vue').default
{ GeneList } = require('./gene_list.coffee')
GeneListAPI = require('./gene_list_api.coffee')
addGeneListModal = require('./modal-add-gene-list.vue').default

module.exports =
    name: 'filterGenes'
    props:
        show: false
        geneListAPI:
            default: undefined
            required: true
    data: () ->
        cur_tab_left: "user"
        cur_tab_right: "add"
        curList: -1 #Do we want a second value so we have one for each list? (predefined and user)
        usingList: true
        listType: 'user' #There are two values representing the current list?
        searchTerm: ""
        showAddGenes: false
        searchedLists: []
        user_sel: -1
        geneLists: []
        curListContents: []
    components:
        modal: Modal
        addGeneListModal: addGeneListModal
    watch:
        searchTerm: (val) ->
            this.set_search_lists(val)
        cur_tab_left: () ->
            this.curList = this.user_sel
            this.set_search_lists(this.searchTerm)
        geneLists: (x) ->
            this.set_search_lists(this.searchTerm)
        geneListAPI: () ->
            this.geneListAPI.get_all_user_geneLists()
                .then((result) =>
                    this.geneLists = result
                    this.$emit('updateGeneList', this.geneLists)
                    )
        user_sel: (sel) ->
            this.curListContents = "Getting Genes..."
            id = this.geneLists[sel].id
            this.geneListAPI.get_geneList(id).then((gl) =>
                this.curListContents = JSON.parse(gl.rows)
                )

    computed:
        curTitle: () ->
            if(this.curList == -1)
                return "None"
            if(this.listType == 'user')
                # this.geneLists[this.user_sel].get_title()
                this.geneLists[this.user_sel].title
            #We now have it behaving properly, but cannot instantiate it correctly. It does not appear correctly.

    methods:
        set_search_lists: (st) ->
            if st == ""
                this.searchedLists = this.geneLists
                return
            gl = this.geneLists
            this.searchedLists = gl.filter((e,i,a) =>
                if !e.title? || !e.description? || !e.id_type?
                    return false
                res = e.title.indexOf(st) > -1 || e.description.indexOf(st) > -1 || e.id_type.indexOf(st) > -1
                return res
            )

        clearList: () ->
            this.inputList = ""
        make_gl: () ->
            genelist = this.inputList
            res = genelist.split(/,|\n|\t/).map((el) -> el.trim()).filter((el) -> el.length > 0)
            newGL = new GeneList(
                name = this.gene_list_title
                genes = res
            )
            newGL
        checkDuplicated: (gl) ->
            if this.geneLists.findIndex((el) -> el.get_title() == gl.get_title()) != -1
                return true
            else
                return false
        saveUserGeneList: () ->
            # this.$emit('submitList', this.geneLists)
            this.$emit('updateGeneList', this.geneLists)
            if this.curList != -1
                this.geneListAPI.get_geneList(this.geneLists[this.curList].id).then((x) =>
                    res = new GeneList(x.title, {rows: JSON.parse(x.rows), columns: JSON.parse(x.columns)}, x.id_type, x.collection_type, x.description)
                    this.$emit('changedCurList', res)
                )
            else
                this.$emit('changedCurList', {})

        # This method should probably append to list by emitting to submit?
        appendToList: (newList) ->
            # this.$emit('addGeneList', newList)
            this.geneListAPI.add_geneList(newList).then((x) =>
                this.geneListAPI.get_all_user_geneLists().then((result) =>
                    this.geneLists = result
                    this.$emit('updateGeneList', this.geneLists)
                    )
            )

        selectList: (index, listType) ->
            this.cur_tab_right = 'display'
            this.listType = listType
            if this.curList != index
                this.curList = index
            else
                this.curList = -1

        removeIdx: (index) ->
            if(index == this.curList)
                this.curList = -1
                this.user_sel = -1
            else if(index < this.curList)
                this.curList -= 1
            this.geneListAPI.remove_geneList(this.geneLists[index].id)
            this.geneLists.splice(index, 1)

        close: () ->
            this.$emit('close')
        closeButton: () ->
            this.saveUserGeneList()
            this.close()

    mounted: () ->
        this.geneLists = []
</script>
