## Quickstart Guide

There are three alternative ways to use Degust. Briefly, these are:

* Upload a CSV of counts per gene to our public server.
* Do your own analysis, and upload a CSV of your analysis to our public server.
* Do your own analysis and create a single HTML file to view and share using degust.py.  

You can check out examples of projects in Degust to see how its done [here](thisisnotareallink).

### Use Degust with per gene read counts
Create your CSV file with read counts per gene - the CSV file requirements are documented on the upload page. You'll then be directed to web page to specify the columns of your CSV including which samples are replicates. The back-end will then analyse your data using voom/limma, and you can visualise the results with Degust.

Using Degust in this manner has the advantage that you can select, within Degust, the conditions you wish to compare. That is, the selected 2 samples and a moderated t-test is performed for each gene. Select 3 or more samples and a moderated F-test is used.

### Use Degust with pre-analysed data
Perform your own differential expression analysis and produce a CSV file of your results - the CSV file requirements are documented on the upload page. You can then specify which columns are which, and visualise your results with Degust.

### Use Degust as a single HTML
Perform your own differential expression analysis and produce a CSV file of your results. You then use a python script, degust.py, to embed your CSV file in an HTML file that can be directly loaded by in browser.

