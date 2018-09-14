### Gene Enrichment API

#### Target two 'simple' methods:
* Foreground & background gene lists
* Single ranked gene list

Avoid using method which requires counts files (FRY).
Both require list of genes to perform gene set testing, however GSEA requires a ranking.

Backend requirements
* Database of various genesets in correct ID type (ENSEMBL/EntrezId for now).
* User to input a gene set which can be tested against various gene sets. (MsigDB, KEGG etc)
* Understanding of how to perform these tests. (Likely use R to do either/both)

Data structure to send:
* test_name: `str` `"Sample Test Title"` - (Probably want 1+ tests per dataset)
* test_id: `int` `12`
* query: (String of JSON encoded object) (May sometimes be proteins)
    * If foreground/background mode:
        * foreground: `str` `"ENSMUSG00000021025"` - (May want to provide ID conversions)
        * background: `str` `"ENSMUSG00000021025"` - (May want to provide ID conversions)
    * If Ranking mode:
        * foreground: `[]` (Each value in array is `{}` of genes and rankings. Maybe I don't want to call it foreground?)
            * Genes: `str` `"ENSMUSG00000021025"`
            * ranking: `float` `1.212` (Use whatever numeric value provided.)
    * fdr_cutoff: `float` `0.05` (Default to 0.05)
    * collection_id: `str` `"123"` (Refers to the collection being tested against. Will need a way to perform tests against your own genesets eventually)

User needs to be able to do: (Front end)
* Take a set of genes (Not necessarily from Degust) and apply tests to them.
* Get back a result of Differentially Enriched gene sets. Apply some simple visualisation to this.

Results: (Get all the same data back as the post + result)
* test_name: `str` `"Sample Test Title"` - (Probably want 1+ tests per dataset)
* test_id: `int` `12`
* query: (String of JSON encoded object) (May sometimes be proteins)
    * foreground: `str` `"ENSMUSG00000021025"` - (May want to provide ID conversions)
    * ranking: `float` `1.212` - (If no ranking is provided, ask to use unraked test) (To be the same length as foreground)
    * background: `str` `"ENSMUSG00000021025"` - (May want to provide ID conversions)
    * cutoff: `float` `0.05` (FDR cutoff for summary)
    * collection_id: `str` `"123"` (Refers to the collection being tested against. Will need a way to perform tests against your own genesets eventually)
* summary:
    * result:
        * sig: `int` (Number of genesets below query.cutoff)
        * extra: `str` (Unsure as to what else can go in there, GSEA makes barcode plots, GOrilla makes GO graphs)
* result: `[]` (String of JSON encoded object) (Imagined as a table)
    * id: `str` `"GO:0060559"` (Name of geneset)
    * geneset_id: `int` `2` (Backend ID which matches the ids in the database so contents can be queried)
    * name: `str` `"positive regulation of calcidiol..."` (Shouldn't always be particularly long)
    * description: `str` `"Any process that increases..."` (Description of the genelist, though it might be too much text to be practical)
    * p_value: `float` `0.00000483`
    * fdr: `float` `0.000689`
* queue_status: `{}` (Only returned if it is still computing.)
    * location: `int` (Location of query in queue - How many queries are ahead of me?)

API Specifics:
* GET:
    * Get all previously performed tests (return ['test_name', 'test_id', 'query', 'summary', 'queue_status'])
        * `/degust/:id/gene_tests/`
        * If none, return `[]`
        * Only return query part, result may be very large depending on the number of genesets tested.

    * Get a single geneset
        * `/degust/:id/gene_tests/{:gene_test_id}`
        * If missing, return error with "Test cannot be found"

* POST:
    * Queue up a new test:
        * `/degust/:id/gene_tests`
        * Using ID's means we shouldn't have an ID collision
        * Return an ID ?

* DEL:
    * Delete/Remove a cached test
        * `/degust/:id/gene_tests/{:gene_test_id}`
        * If missing, return error with "Test cannot be found"

Will at some point likely need to apply some sort of gene ID conversion for convenience. If this is the case, will need another column to show which genes were converted.

Visualisation of enrichment is another thing to consider.