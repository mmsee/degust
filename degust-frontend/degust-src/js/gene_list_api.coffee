{ GeneList } = require('./gene_list.coffee')

# Idea here is that total is simply replaced with an AJAX through the API

get_all_geneLists = (code) ->
    new Promise((resolve) =>
        a = require('./def.json')
        res = a.map((e) => new GeneList(e.title[0], e.members))
        resolve(res)
    )

get_geneList = (total, name) ->
    res = total.filter((e) => e.title == name)
    console.log(res)

set_geneList = (total, geneset) ->
    total[total.length] = geneset
    return total

find_geneList = (total, st) ->
    if(st != "")
        term = st.toLowerCase()
        res = total.filter((gl) =>
            gl.get_title().toLowerCase().includes(term) ||
            gl.get_members().map((e) => e.toLowerCase()).filter( (gene) =>
                gene.includes(term)
            ).length > 0
        )
        return res
    else
        total

modify_geneList = (newList) ->
    console.log("Updated with " + newlist)

#This is a fake dataset to use before the Ruby API is developed.
#Using this instead of AJAX GET/SET
get_all_predef_geneLists = () =>
    new Promise((resolve) =>
        a = JSON.parse(require('./predef.json')[0])
        res = a.map((e) => new GeneList(e.title[0], e.members))
        resolve(res)
    )

module.exports =
    get_geneList: get_geneList
    set_geneList: set_geneList
    find_geneList: find_geneList
    modify_geneList: modify_geneList
    get_all_geneLists: get_all_geneLists
    get_all_predef_geneLists: get_all_predef_geneLists

