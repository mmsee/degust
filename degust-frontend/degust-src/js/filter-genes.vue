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
                                <li :class='{active: cur_tab_left=="predef"}'>
                                    <a @click='cur_tab_left="predef";cur_tab_right="display"'>Predefined</a>
                                </li>
                            </ul>
                            <br/>
                            <div id='glSearchBox'><input type='text' placeholder="Search..." v-model="searchTerm" style='padding:2px;'></div>
                            <div v-if='cur_tab_left=="user"' class='tableScroll'>
                                <table class='userListTable'>
                                    <tr :key='index' v-for='(list, index) in searchedLists' v-bind:class='{"selected": (index == curList)}'>
                                        <td @click='selectList(index, "user"), user_sel = index'>{{ list.get_title() }}</td>
                                        <td @click='selectList(index, "user"), user_sel = index'>{{ list.get_members().length }} ID's</td>
                                        <td class='removeList'><button type="button" class="btn btn-danger-outline" @click='removeIdx(index)'><span class='glyphicon glyphicon-minus'></span></button></td>
                                    </tr>
                                </table>
                            </div>
                            <div v-if='cur_tab_left=="predef"' class='tableScroll'>
                                <table class='userListTable'>
                                    <tr :key='list.title' v-for='(list, index) in searchedLists' v-bind:class='{"selected": (index == curList)}'>
                                        <td @click='selectList(index, "predef"), predef_sel = index'>{{ list.get_title() }}</td>
                                        <td @click='selectList(index, "predef"), predef_sel = index'>{{ list.get_members().length }} ID's</td>
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
                                <div :key="index" v-for="(names, index) in cur_tab_left ==='user'? geneLists[curList].get_members() : predefGeneLists[curList].get_members()">
                                    <div><span>{{ names }}</span></div>
                                </div>
                            </div>
                            <div v-else>
                                <h5>No list Selected!</h5>
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
            @geneset='appendToList'
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
    data: () ->
        cur_tab_left: "user"
        cur_tab_right: "add"
        curList: -1 #Do we want a second value so we have one for each list? (predefined and user)
        usingList: true
        listType: 'user' #There are two values represeinting the current list?
        searchTerm: ""
        showAddGenes: false
        searchedLists: []
        predef_sel: -1
        user_sel: -1
    components:
        modal: Modal
        addGeneListModal: addGeneListModal
    props:
        show: false
        geneLists:
            default: []
        predefGeneLists:
            default: []
    watch:
        searchTerm: (val) ->
            this.set_search_lists(val)
        cur_tab_left: () ->
            if(this.cur_tab_left == 'user')
                this.curList = this.user_sel
            else
                this.curList = this.predef_sel
            this.set_search_lists(this.searchTerm)
        geneLists: () ->
            this.set_search_lists(this.searchTerm)
    computed:
        curTitle: () ->
            if(this.curList == -1)
                return "None"
            if(this.listType == 'user')
                this.geneLists[this.user_sel].get_title()
            else if(this.listType == 'predef')
                this.predefGeneLists[this.predef_sel].get_title()
            #We now have it behaving properly, but cannot instantiate it correctly. It does not appear correctly.

    methods:
        set_search_lists: (st) ->
            gl = []
            if(this.cur_tab_left == 'user')
                gl = this.geneLists
            else if(this.cur_tab_left == 'predef')
                gl = this.predefGeneLists
            this.searchedLists = GeneListAPI.find_geneList(gl, st)

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
            #These three are emitted so that the compare-single knows about which gene list is selected.
            this.$emit('submitList', this.geneLists)
            this.$emit('changedCurList', this.curList)
            this.$emit('changedListType', this.listType)

        # This method should probably append to list by emitting to submit?
        appendToList: (value) ->
            # Pass to parent?
            # this.$emit('addGeneList')
            # On 200, emit the new genelist? Or should the gene list be emitted to the parent and then it be updated?
            if (GeneListAPI.add_geneList(this.geneLists, value) == 200)
                console.log(value)
        selectList: (index, listType) ->
            this.cur_tab_right = 'display'
            this.listType = listType
            this.curList = index
        removeIdx: (index) ->
            # if (GeneListAPI.remove_geneList(this.geneLists[this.curList].get_title(), this.code) == 200)
            if(index == this.curList)
                this.curList = -1
                this.user_sel = -1
            else if(index < this.curList)
                this.curList -= 1
            this.geneLists.splice(index, 1)
            # this.$emit(removedlist, index)
            # or, simply call GeneListAPI.
        close: () ->
            this.$emit('close')
        closeButton: () ->
            this.saveUserGeneList()
            this.close()

    mounted: () ->
        # this.$emit('listType', "user")
</script>
