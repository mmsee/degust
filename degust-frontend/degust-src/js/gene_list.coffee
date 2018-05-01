# Gene-list class
# Each list has:
#   List name
#   Members

class GeneList
    constructor: (name, genes) ->
        this.set_title(name)
        this.set_members(genes)

    _deduplicate: () ->
        this.members.filter((arr, i) ->
            a.indexOf(a) == i)

    get_title: () ->
        return this.title
    set_title: (name) ->
        this.title = name

    get_members: () ->
        return this.members
    set_members: (members) ->
        this.members = members

module.exports =
    GeneList: GeneList