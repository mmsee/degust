# Gene-list class
# Each list has:
#   List name
#   Members

class GeneList
    constructor: (name, data, id_type, collection_type, desc) ->
        this.set_title(name)
        this.set_id_type(id_type)
        this.set_collection_type(collection_type)
        this.set_description(desc)
        this.data = data


    get_title: () ->
        return this.title
    set_title: (name) ->
        this.title = name

    get_description: () ->
        return this.description
    set_description: (desc) ->
        this.description = desc

    get_columns: () ->
        return this.data.columns
    set_columns: (cols) ->
        this.data.columns = cols

    get_rows: () ->
        return this.data.rows
    set_rows: (rows) ->
        this.data.rows = rows

    get_id_type: () ->
        return this.id_type
    set_id_type: (id_type) ->
        this.id_type = id_type

    get_collection_type: () ->
        return this.collection_type
    set_collection_type: (collection_type) ->
        this.collection_type = collection_type

    get_columns: () ->
        return this.data.columns
    set_columns: (columns) ->
        this.data.columns = columns

    #Function to get members out of rows.
    #Only returns the idx column
    get_members: () ->
        row = this.get_columns().idx
        result = this.get_rows().map((e) =>
            e[row]
        )
        return result


module.exports =
    GeneList: GeneList