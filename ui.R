### SHINY UI
ui <-  fluidPage(
  # theme = shinytheme("darkly"),
  theme = shinytheme("slate"),
  
  tags$head(tags$style(HTML('
    #selectedGenesByLasso{
        //color: #fc6600;
    }
    
    #selectedGenes_postFilter{                        
      color: orange;
    }
    
    #genesToTrack {
      color: LimeGreen;
    }
    
    #selectedGenes_preFilter{                        
      //color: #03ac13;
    }
    
    .selectize-input {
      height: 180px; 
    }
    
    .selectize-input > div {
      //color: #03ac13 !important;
    }
  
    [for="fdr"] {
      color : #777777;
    }
    
    [for="fdr_txt"] {
      color : #777777;
    }
    
    #filter_val_down {
    background-color:rgb(91,156,213)
    }
    #filter_val_notsig {
    background-color:darkgray
    }
    #filter_val_up {
    background-color:rgb(255,127,127)
    }

    
    '))),
  fluidRow(
    useShinyjs(),
    column(12, h1("MA Visualization Tool")),
    column(12,fluidRow(
      column(2,
        h4("Leyenda"),
        plotOutput("legendPlot", height = 200, width = 100),
        br(),
        h4("Filtros"),
        column(12, h5(div("Eje X"))),
        column(12, sliderInput("filter_slider_cutOffX", label=NULL, step=0.1, min=0, max=100, value=c(0,100))),
        column(12, h5(div("Eje Y"))),
        column(12, sliderInput("filter_slider_cutOffY", label=NULL, step=1, min=0, max=16, value=0)),
      ),
      column(7,
            plotlyOutput("maPlot", height = 500),
            br()
      ),
      column(3, style="text-align:center;",
        h4(id="label_selectedGenes_postFilter", "Genes Seleccionados(0)"),
        disabled(textAreaInput(inputId="selectedGenes_postFilter", label=NULL,
                              value="",placeholder="Los genes seleccionados apareceran aqui",
                              rows="5", width="100%")),
        h4(id="label_track_genes", "Genes Guardados(0)"),
        disabled(textAreaInput(inputId="genesToTrack", label=NULL,
                                value="", placeholder="Aqui podra guardar varias selecciones",
                                width="100%", rows="5")),
        actionButton(inputId="buttonClearSelectedGenes", label="Limpiar seleccion", width = '50%'),
        actionButton(inputId="buttonTrackSelectedGenes", label="Guardar seleccion", width = '50%'),
        actionButton(inputId="buttonClearTrackedGenes", label="Limpiar guardados", width = '50%'),
      )
    )),

    column(4,
      h4("Cargar datos MA"),
      fileInput("loadData", label=NULL,
        accept = c(
          "text/csv",
          "text/comma-separated-values,text/plain",
          ".csv",
          ".RData")
      ),
      actionButton(inputId="buttonLoadTestData", label="Datos de prueba", width = '30%'),
      actionButton(inputId="buttonResetUI", label="Reiniciar", width = '30%'),
      downloadButton(outputId="buttonDownloadTestDataCSV", label=".csv"),
      bsTooltip("buttonLoadTestData", "Al seleccionar se insertara datos de ejemplo",
                "right", trigger = "hover"),
      bsTooltip("buttonDownloadTestDataCSV", "Descarga los datos de ejemplo en formato CSV",
                "right", trigger = "hover"),
      bsTooltip("buttonResetUI", "Reinicia todo la pantalla",
                "right", trigger = "hover"),
    ),
    column(4,
      h4("Guardar datos"),
      downloadButton(outputId="buttonSaveMAPlotPNG", label=".png"),
      bsTooltip("buttonSaveMAPlotPNG", "Guardar el plot como .png",
                "right", trigger = "hover"),
      downloadButton(outputId="buttonSaveMAPlotRDATA", label=".RData"),
      bsTooltip("buttonSaveMAPlotRDATA", "Guardar el plot como un archivo.RData",
                "right", trigger = "hover")
    ),
    column(4,
      h4("Seleccionar tipo de grafico"),
      actionButton(inputId="", label="MA plot", width = '50%'),
      actionButton(inputId="", label="Plot 2", width = '50%'),
      actionButton(inputId="", label="Plot 3", width = '50%'),
    ),
    column(12,style="display:none;",
          column(4,
                 column(6,
                        h4("Search Genes"),
                        # Ref for selection event: https://stackoverflow.com/questions/50168069/r-shiny-selectize-selected-event)
                        # Ref for copy/pasting into a selectize: https://github.com/rstudio/shiny/issues/1663
                        selectizeInput(inputId='selectGenesByName', label=NULL, choices=NULL, multiple=TRUE,
                                       options = list(
                                         splitOn = I("(function() { return /[,; ]/; })()"), #allow for copy-paste
                                         create = I("function(input, callback){return {value: input,text: input};}"),
                                         render = I("{item: function(item, escape) {return '<div class=\"item\" onclick=\"Shiny.onInputChange(\\\'selectGenesByName_click\\\', \\\'' + escape(item.value) + '\\\')\">' + escape(item.value) + '</div>';}}")
                                       ))%>% 
                          helper(type = "inline",
                                 title = "Gene search by names",
                                 content = c("Copy-paste gene names here.",
                                             "Those not available in the loaded MA data will be indicated and can be copied.",
                                             "Those available can be filtered and tracked..."),
                                 size = "m")
                 ),
                 column(6,
                        h4(id="label_selected_genes", "Lassoed Genes (0)"),
                        disabled(textAreaInput(inputId="selectedGenesByLasso", label=NULL,
                                               value="",placeholder="Genes selected by lasso/box in the plot will appear here... (Double-click the plot to clear)",
                                               width="100%", rows="9"))
                 ),
                 br(),
                 column(12,
                        radioGroupButtons(
                          inputId='filterKeep', choices = c('Keep all', 'Keep singles', 'Keep multiples'), selected = c('Keep all'), status = 'default',
                          justified = TRUE, checkIcon = list(yes = icon("ok",lib = "glyphicon"), individual=T) 
                        ),
                        bsTooltip("filterKeep", "Cross filter between Searched and Lassoed genes.", trigger = "hover")
                 )
          ),
      fluidRow(
        column(4, 
                bsButton(
                  inputId = "filter_val_down", 
                  label = "Down -",
                  type = "toggle",
                  block=TRUE,
                  value = TRUE, 
                  icon =  icon("ok",lib = "glyphicon"))
        ),
        column(4, 
                bsButton(
                  inputId = "filter_val_notsig", 
                  label = "Not Sig.",
                  type = "toggle",
                  block=TRUE,
                  value = TRUE, 
                  icon =  character(0))
        ),
        column(4, 
                bsButton(
                  inputId = "filter_val_up", 
                  label = "Up +",
                  type = "toggle",
                  block=TRUE,
                  value = TRUE, 
                  icon =  icon("ok",lib = "glyphicon"))
        )
      ),
      fluidRow(
        column(8, h5(id="TopK_genes","No Top/Bottom rank filter by P-value if 0")
                %>% 
                    helper(type = "inline",
                          title = "Top/Bottom-K Genes by P-value",
                          content = c("No Top/Bottom rank filter on P-value if K=0",
                                      "Select the |K| most significant genes (lowest P-value) if K>0.",
                                      "Select the |K| least significant genes (highest P-value) if K<0."),
                          size = "m")),
          column(4, numericInput(inputId='filter_val_topK', label=NULL, value = 0))
      ),
      h4("Save Filtered MA data"),
      fluidRow(
        column(4, actionButton(inputId="buttonTableView", label="Details...")),
        column(4, offset=0, downloadButton(outputId="buttonDownloadGenesCSV", label=".csv")),
        column(4, offset=0, downloadButton(outputId="buttonDownloadGenesRDATA", label=".RData")),
        bsTooltip("buttonTableView", "Show a Table view of the filtered data.",
                  "right", trigger = "hover"),
        bsTooltip("buttonDownloadGenesCSV", "Save the filtered data as a CSV file.",
                  "left", trigger = "hover"),
        bsTooltip("buttonDownloadGenesRDATA", "Save a .RData file containing the filtered data in MAdata dataframe, the plot in MAplot ggplot, and the notes as a text in MAnotes.",
                  "left", trigger = "hover")
      ),
      column(2,
        br(),
        br(),
        br(),
        h4(id="label_pvalue","P-value Cut-off (FDR)"),
        sliderTextInput(inputId="fdr", 
                      label="Pre-defined",
                      grid = TRUE,
                      force_edges = TRUE,
                      choices = c(0.001, 0.01, 0.05, 0.1, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0),
                      selected = handle$fdrVal),
      numericInput(inputId="fdr_txt", 
                    label="Manual ]0,1[", 
                    value=handle$fdrVal, 
                    min = 0, max = 1, step = 0.001),
      ),
      checkboxInput(inputId="filter_chk_cutOffX_reverse", label="Reverse interval"),
      checkboxInput(inputId="filter_chk_cutOffY_reverse", label="Reverse interval")
    )
  )
)

