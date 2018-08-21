{ GeneList } = require('./gene_list.coffee')

# Idea here is that total is simply replaced with an AJAX through the API
class geneListAPI
    constructor: (code, token) ->
        this.code = code
        this.token = token

    # ID of genelist
    get_geneList: (list_id) ->
        code = this.code
        $.ajax(
            type: "GET"
            url: window.location.origin + '/degust/' + code + '/gene_lists/' + list_id
            dataType: "json"
        ).done((x) =>
            return x
        )

    add_geneList: (list) ->
        token = this.token
        code = this.code
        $.ajax(
            type: "POST"
            beforeSend: (xhr) =>
                xhr.setRequestHeader('X-CSRF-Token', token)
            url: window.location.origin + '/degust/' + code + '/' + 'gene_lists'
            data:
                title: list.get_title()
                description: list.get_description()
                id_type: list.get_id_type()
                collection_type: list.get_collection_type()
                rows: JSON.stringify(list.get_rows())
                columns: JSON.stringify(list.get_columns())
        ).done((x) =>
            return 200
        )

    find_geneList: (total, st) ->
        if(st != "")
            term = st.toLowerCase()
            res = total.filter((gl) =>
                gl.title().toLowerCase().includes(term) ||
                gl.data.rows.map((e) => e.toLowerCase()).filter( (gene) =>
                    gene.includes(term)
                ).length > 0
            )
            return res
        else
            total

    remove_geneList: (list_id) ->
        code = this.code
        token = this.token
        $.ajax(
            type:"DELETE"
            beforeSend: (xhr) -> xhr.setRequestHeader('X-CSRF-Token', token)
            url: window.location.origin + '/degust/' + code + '/' + 'gene_lists/' + list_id
        ).complete((e) =>
            if e.status == 200
                console.log("Deleted: " + list_id)
        )

    #No longer need a concept of 'predefined genelists'
    get_all_user_geneLists: () =>
        code = this.code
        $.ajax(
            type: "GET"
            url: window.location.origin + '/degust/' + code + '/' + 'gene_lists'
            dataType: "json"
        ).done((x) =>
            res = x.map((e) =>
                new GeneList(e.title, {rows:e.rows, columns:e.columns}, e.id_type, e.collection_type, e.description)
            )
            return(res)
        )

module.exports =
    GeneListAPI: geneListAPI

