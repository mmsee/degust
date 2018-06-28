<style scoped>
#gene-filter-modal >>> .modal-content {
    width: 200%;
    margin-left: -50%;
}
#filter-textarea {
    width: 100%;
    height: 300px;
    resize:vertical;
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

.userListTable >>> td, th {
    border: 1px solid #dddddd;
    text-align: left;
    padding: 10px;
}

.userListTable >>> .removeList {
    border: 1px solid #dddddd;
    text-align: center;
    font-weight: bolder;
    color: #ff6666;
    padding: 8px;
}

.userListTable >>> .selected {
    border: 1px solid #000000;
    color: #00aaff;
    font-weight: bolder;
    background-color: #eeeeee;
}

.removeList >>> .btn-outline-danger{
    font-size: 8pt;
}

#displaydiv {
    height: 400px;
    overflow-y: scroll;
    /* background-color: lightgrey; */
    border-style: none inset inset none;
    border-width: 2px;

}

</style>

<template>
    <modal
        :showModal='show'
        :closeAction='close'
        id='gene-filter-modal'
        >
        <h4 slot='header'>{{ usingList? (geneLists.length == 0? 'No lists entered' :'Using: ' + curTitle) : 'Gene list filtering toggled off' }}</h4>
        <div slot='body'>
            <div class='row'>
                <div class='col-xs-5'>
                    <div class='tableWrap'>
                        <ul class="nav nav-tabs">
                            <li :class='{active: cur_tab_left=="user"}'>
                                <a @click='cur_tab_left="user";'>Your Gene Lists</a>
                            </li>
                            <li :class='{active: cur_tab_left=="predef"}'>
                                <a @click='cur_tab_left="predef";cur_tab_right="display"'>Predefined</a>
                            </li>
                        </ul>
                        <div v-if='cur_tab_left=="user"' class='tableScroll'>
                            <table class='userListTable'>
                                <tr :key='list.title' v-for='(list, index) in geneLists' v-bind:class='{"selected": (index == curList)}'>
                                    <td @click='selectList(index, "user")'>{{ list.get_title() }}</td>
                                    <td @click='selectList(index, "user")'>{{ list.get_members().length }} ID's</td>
                                    <td class='removeList' @click='removeIdx(index)'><button type="button" class="btn btn-outline-danger">X</button></td>
                                </tr>
                            </table>
                        </div>
                        <div v-if='cur_tab_left=="predef"' class='tableScroll'>
                            <table class='userListTable'>
                                <tr :key='list.title' v-for='(list, index) in predefList' v-bind:class='{"selected": (index == curList)}'>
                                    <td @click='selectList(index, "predef")'>{{ list.get_title() }}</td>
                                    <td @click='selectList(index, "predef")'>{{ list.get_members().length }} ID's</td>
                                </tr>
                            </table>
                        </div>
                    </div>
                </div>
                <div class='col-xs-7' style="">
                    <ul class='nav nav-tabs'>
                        <li :class='{active: cur_tab_right=="display"}' >
                            <a @click='cur_tab_right="display"'>Display</a>
                        </li>
                        <li :class='{active: cur_tab_right=="add"}' v-if="cur_tab_left==='user'">
                            <a @click='cur_tab_right="add"'>Add Lists</a>
                        </li>
                    </ul>
                    <div v-if='cur_tab_right=="display"' id='displaydiv'>
                        <div :key="names" v-for="(names) in listType==='user'? geneLists[curList].get_members() : predefList[curList].get_members()">
                            <div><span>{{ names }}</span></div>
                        </div>
                    </div>
                    <div v-if='cur_tab_right=="add"'>
                        <input v-model='gene_list_title' placeholder='Enter a Gene List Title'>
                        <br></br>
                        <textarea id='filter-textarea' v-model="inputList" placeholder="Type or paste your delimited genes here"></textarea>
                    </div>
                </div>
            </div>
        </div>
        <div slot='footer'>
            <button class='btn btn-primary' @click='clearList'>Clear</button>
            <button class='btn btn-primary' @click='addToList'>Add</button>
            <button class='btn btn-primary' @click='closeButton'>Save</button>
        </div>
    </modal>
</template>

<script lang='coffee'>

Modal = require('modal-vue').default
{ GeneList } = require('./gene_list.coffee')
GeneListAPI = require('./gene_list_api.coffee')

module.exports =
    name: 'filterGenes'
    data: () ->
        inputList: ""
        cur_tab_left: "user"
        cur_tab_right: "add"
        gene_list_title: ""
        curList: 0
        usingList: true
        predefList: []
        listType: 'user'
    components:
        modal: Modal
    props:
        show: false
        geneLists:
            default: []
        predefGeneLists:
            default: []
    computed:
        curTitle: () ->
            if(this.listType == 'user')
                this.geneLists[this.curList].get_title()
            else if(this.listType == 'predef')
                this.predefList[this.curList].get_title()
    methods:
        clearList: () ->
            this.inputList = ""
        make_gl: () ->
            genelist = this.inputList
            res = genelist.toLowerCase().split(/,|\n|\t/).map((el) -> el.trim()).filter((el) -> el.length > 0)
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
        filterList: () ->
            this.$emit('submitList', this.geneLists, 'user')
            this.$emit('listType', this.listType)
            this.$emit('changedCurList', this.curList)
        addToList: () ->
            if this.gene_list_title == ''
                alert('Title already Exists')
                return 0
            else if this.checkDuplicated(this.make_gl())
                alert('Duplicated Gene List')
                return 0
            else
                res = this.geneLists.push(this.make_gl())
                this.gene_list_title = ''
                this.inputList = ''
                return res
        selectList: (index, listType) ->
            this.cur_tab_right = 'display'
            this.listType = listType
            this.curList = index
        removeIdx: (index) ->
            this.geneLists.splice(index, 1)
            this.curList = 0
        close: () ->
            this.$emit('close')
        closeButton: () ->
            this.filterList()
            this.close()
        get_predef: () ->
            this.predefList = await GeneListAPI.get_all_predef_geneLists()

    mounted: () ->
        this.get_predef()
        #Initialise and pass out gene lists.
        #
        # this.$emit('submitList', this.geneLists, 'user')
        this.$emit('listType', "user")
</script>
