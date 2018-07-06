
<style scoped>
    .customModal >>> .modal-content {
        width: 90%;
        margin-left: 5%;
        margin-top: 20%;
    }

    #geneListDescription {
        resize: none;
        height: 40px;
        width: 80%;
        transition: all 0.4s;
    }

    #geneListDescription:focus {
        resize: none;
        height: 110px;
        transition: all 0.4s;
    }

    .filter-textarea {
        height: 60px;
        width: 80%;
        resize: vertical;
    }

    .filter-textarea:focus {
        height: 110px;
        transition: all 0.4s;
    }

    .form-block{
        line-height: 200%;
    }

    table .label-column{
        vertical-align: top;
        text-align: right;
        table-layout: fixed;
        width: 120px;
    }
    table .input-column{
        vertical-align: top;
        table-layout: fixed;
        width: 300px;
    }

    #add-table > tr, td {
        height: 30px;
        padding: 3px;
    }
</style>

<template>
    <div>
        <modal
            class='customModal'
            :showModal='showAddList'
            :closeAction='close'
        >
            <div slot='header'>
                Add a Gene List
            </div>
            <div slot='body'>
                <div class='form-block'>
                    <table id='add-table'>
                        <tr v-tooltip='tip("Name of the gene list. This must be unique")'>
                            <td class='label-column'>Name</td>
                            <td class='input-column'><input placeholder="Enter a name" v-model='listName'></td>
                        </tr>
                        <tr v-tooltip='tip("ID Type of gene, Ensembl, Entrez, Symbolic etc.")'>
                            <td class='label-column'>ID Type</td>
                            <td class='input-column'><input placeholder="ID Type of Genes" v-model='idType'> <br/> <!-- dropdown menu --></td>
                        </tr>
                        <tr v-tooltip='tip("Organism Name to be used for gene id matching")'>
                            <td class='label-column'>Organism</td>
                            <td class='input-column'><input placeholder="Organism Name" v-model='organismName'> <br/> <!-- Maybe this should be dropdown menu --></td>
                        </tr>
                        <tr v-tooltip='tip("Description of gene list (Optional)")'>
                            <td class='label-column'>Description</td>
                            <td class='input-column'><textarea class="form-control" type="text" v-model='listDescription' placeholder="Gene List Description" id="geneListDescription"/></td>
                        </tr>
                        <tr v-tooltip='tip("Gene List. Genes are separated by spaces, on lines or commas")'>
                            <td class='label-column'>Gene List</td>
                            <td class='input-column'><textarea class="form-control filter-textarea" type="text" v-model="inputList" placeholder="Type or paste your delimited genes here"></textarea></td>
                        </tr>
                    </table>
                </div>
            </div>
            <div slot='footer'>
                <button class='btn btn-warning pull-left'>Clear all fields</button>
                <button class='btn btn-success' @click='addToList' :disabled="!validTotalInput">Save</button>
                <button class="btn btn-primary" @click='closeButton'>Cancel</button>
            </div>
        </modal>
    </div>
</template>

<script lang='coffee'>

Modal = require('modal-vue').default
{ GeneList } = require('./gene_list.coffee')

module.exports =
    name: 'addGeneListModal'
    data: () ->
        listName: ""
        idType: ""
        organismName: ""
        listDescription: ""
        inputList: ""
    components:
        modal: Modal
    props:
        showAddList: false
        allGeneTitles: null
    computed:
        # Returns true if valid. This is passed to a "disabled" so ! the value there
        validTotalInput: () ->
            if (this.listName != "" && this.idType != "" && this.organismName != "" && this.inputList != "")
                return true
            else
                false
    methods:
        tip: (txt) ->
            {content:txt, placement:'left'}
        addToList: () ->
            if this.allGeneTitles.indexOf(this.listName) == -1
                console.log(this.allGeneTitles.findIndex((e) -> e == this.listName), this.allGeneTitles)
                gl = new GeneList(
                    name = this.listName
                    genes = this.inputList.split(/,|\n|\t/).map((el) -> el.trim()).filter((el) -> el.length > 0)
                )
                this.$emit('geneset', gl)
                this.close()
            else
                alert("Gene Name already exists!")

        close: () ->
            this.$emit('close')
        closeButton: () ->
            this.close()


</script>
