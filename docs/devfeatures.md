### New Features: Frontend
<sup> This list is not comprehensive and some features may not yet be live (but are implemented)</sup>    

#### General
*  Dev version added. This can be accessed from the `Your data` page and clicking the drop down arrow and then clicking `View with dev`. 
    <p align="center">
    <img width="220" height="200" src="https://i.imgur.com/fn7F6Ob.png">
    </p>    
    *  Clicking `View` will show the stable version of Degust - "Degust Classic" (3.1.0)

#
*  UI update:
    *  Gene Strip Chart has been made more prominent by having it always visible on the right
    *  Controls and options shifted to left side
    *  Degust is wider to make better use of wide screens   

#
*  Contrasts can be used to test interactions between groups of conditions: 
    *  These are set on the configure page

#
*  3D MDS plot images can be saved: 
    *  MDS plots can have the level of moderation modified

#
*  Experiment descriptions can now be added on the configure page
    *  These can be viewed by hovering on or clicking `Show Description`

#
*  Datasets can now be copied, meaning that users can copy a shared and locked dataset

#
*  Datasets can also now be deleted from the config page

#
*  Gene filter added: 
    *  A gene filter can be applied to the dataset by clicking the `Create Filter` button
    *  Adding a filter is done by adding a list of delimited genes to the text box.
    *  Filter checks for exact match from entries in 
    *  Unlike the Gene Table searchbox this will filter all plots and tables

#
*  Gene table searchbox is searchable by keywords:
    *  More than one search term can be used
    *  Terms are delimited by commas
    *  Gene Table will search through the provided "Info columns" set on the configure page
    *  Note that this does not filter the genes shown in plots and only filters the gene table for this functionality please use the provided gene filter

#
*  Gene table's columns can be shown/hidden from context menu accessable from cog icon
    *  At least one column must be shown
    

#### Proteomics
*  Degust is now able to support the maxQuant format for proteomics. 
    *  Proteomics datasets have their own set of QC plots
        *  CV-histogram
        *  Intensity Histogram (Also shows imputed proportions)
        *  etc.
    *  Intensities can be imputed and the values normalised with limma for DE proteins
        *  Threshold to keep values can be modified from the configure page

*  Gene Table is able to query Uniprot for ID lookup for more information


#### RNASeq
*  RLE box and whisker QC plot added
*  `View SampleWeights` has been replaced with `View Extra Information` which provides information related to normalisation not usually needed.
