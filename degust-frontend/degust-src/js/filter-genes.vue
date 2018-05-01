<style scoped>
#gene-filter-modal >>> .modal-content {
    width: 150%;
    margin-left: -25%;
}
#filter-textarea {
    width: 100%;
    height: 300px;
    resize:vertical;
}

.userListTable {
    font-family: arial, sans-serif;
    border-collapse: collapse;
    width: 100%;
}

.userListTable >>> td, th {
    border: 1px solid #dddddd;
    text-align: left;
    padding: 8px;
}

.userListTable >>> tr:nth-child(even) {
    background-color: #dddddd;
}

.userListTable >>> .removeList {
    border: 1px solid #dddddd;
    text-align: center;
    font-weight: bolder;
    color: #ff6666;
    padding: 8px;
}

.userListTable >>> .selected {
    color: #bada55;
}


</style>

<template>
    <modal
        :showModal='show'
        :closeAction='close'
        id='gene-filter-modal'
        >
        <h4 slot='header'>{{ usingList? (geneLists.length == 0? 'No lists entered' :'Using: ' + geneLists[curList].get_title()) : 'Gene list filtering toggled off' }}</h4>
        <div slot='body'>
            <div class='row'>
                <div class='col-xs-4'>
                    <ul class="nav nav-tabs">
                        <li :class='{active: cur_tab=="user"}'>
                            <a @click='cur_tab="user"'>Your Gene Lists</a>
                        </li>
                        <li :class='{active: cur_tab=="predef"}'>
                            <a @click='cur_tab="predef"'>Predefined</a>
                        </li>
                    </ul>
                    <div v-if='cur_tab=="user"'>
                        <table class='userListTable'>
                            <tr v-for='(list, index) in geneLists' v-bind:class='{"selected": (index == curList)}'>
                                <td @click='selectList(index)'>{{ list.get_title() }}</td>
                                <td @click='selectList(index)'>{{ list.get_members().length }} ID's</td>
                                <td class='removeList' @click='removeIdx(index)'><button type="button" class="btn btn-outline-danger">X</button></td>
                            </tr>
                        </table>
                    </div>
                    <div v-if='cur_tab=="predef"'>
                        <h3>PREDEF TAB</h3>
                    </div>
                </div>
                <div class='col-xs-8'>
                    <input v-model='gene_list_title' placeholder='Enter a Gene List Title'>
                    <br></br>
                    <textarea id='filter-textarea' v-model="inputList" placeholder="Type or paste your delimited genes here"></textarea>
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

module.exports =
    name: 'filterGenes'
    data: () ->
        inputList: ""
        cur_tab: "user"
        gene_list_title: ""
        geneLists: []
        curList: 0
        usingList: true
    components:
        modal: Modal
    props:
        show: false
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
            this.$emit('submitList', this.geneLists)
            this.$emit('changedCurList', this.curList)
        addToList: () ->
            if this.gene_list_title == ''
                alert('Title already Exists')
                return 0
            else if this.checkDuplicated(this.make_gl())
                alert('Duplicated Gene List')
                return 0
            else
                return this.geneLists.push(this.make_gl())
        selectList: (index) ->
            this.curList = index
        removeIdx: (index) ->
            this.geneLists.splice(index, 1)
            this.curList = 0
        close: () ->
            this.$emit('close')
        closeButton: () ->
            this.filterList()
            this.close()

    # mounted: () ->
</script>
