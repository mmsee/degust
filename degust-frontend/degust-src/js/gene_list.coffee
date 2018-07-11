# Gene-list class
# Each list has:
#   List name
#   Members

class GeneList
    constructor: (name, data, id_type, collection_type) ->
        this.set_title(name)
        this.set_members(data)
        # this.set_id_type(id_type)
        # this.set_collection_type(collection_type)

    get_title: () ->
        return this.title
    set_title: (name) ->
        this.title = name

    get_members: () ->
        return this.members
    set_members: (members) ->
        this.members = members

    get_id_type: () ->
        return this.id_type
    set_id_type: (id_type) ->
        this.id_type = id_type

    get_collection_type: () ->
        return this.collection_type
    set_id_type: (collection_type) ->
        this.collection_type = collection_type

    get_columns: () ->
        return this.columns
    set_columns: (columns) ->
        this.columns = columns

module.exports =
    GeneList: GeneList