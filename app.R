library(shiny)
library(jpeg)
library(httr)
library(XML)
library(stringr)
library(ggplot2)
library(Kmisc)
library(jpeg)
library(Rmisc)
library(grid)
library(highcharter)

options(scipen = 999) 

ui = shinyUI(fluidPage(
  
  titlePanel("Face and Emotion recognition tool"),
  
  sidebarLayout(
    # sidebar elements
    sidebarPanel(
      textInput("url", "Please define the image source (url)", value = 'http://thelala.com/wp-content/uploads/2016/03/rtr4yevj_0.jpg', placeholder ='http://thelala.com/wp-content/uploads/2016/03/rtr4yevj_0.jpg'),
      print("or"),
      br(),
      br(),
      fileInput(inputId = 'files', 
                label = 'Select an Image',
                multiple = F,
                accept=c('image/png', 'image/jpeg'))
      ),
    # main panel elements
    mainPanel(
      tabsetPanel(
        tabPanel("Plot",
                 fluidRow(
                   br(),
                   column(12, align = "center", h3(textOutput("age")))),
                   br(),
                   fluidRow(
                    column(6, plotOutput("pic")),
                    column(6, plotOutput("hist"))
                 )), 
        tabPanel("Raw Data", tableOutput("data"))
      )
    )
  )
))

server = function(input, output) {

  # Saves the uploaded item onto a selected place  
  # observeEvent(input$files, {
  #   inFile <- input$files
  #   if (is.null(inFile))
  #     return()
  #   file.copy(inFile$datapath, file.path('C:\\Users\\zsolt\\Documents\\', inFile$name) )
  # })

  output$pic = renderPlot({
    url = input$url
    # Download the selected picture from the given url and save it
    download.file(url, 'host_pic.jpg', mode = 'wb')
    pic = readJPEG('host_pic.jpg', native = T)
    raster = rasterGrob(pic, interpolate  = T)
    # Plot the picture
    qplot(geom ='blank') +
      annotation_custom(raster, xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf) +
      geom_point()
    # Remove the downloaded picture
 #   file.remove('host_pic.jpg')
  })
  
  output$hist = renderPlot({
    url = input$url
    emotion_key = 'e84596b3f9b64377904e2e896dde8f42'
    face_key = 'a79c66ae113f44a6857fbf10ba0bede5'

    # Define image
    mybody = list(url = url)
    
    ##### Emotion API
    # Define Microsoft API URL to request data
    emotion_url = 'https://api.projectoxford.ai/emotion/v1.0/recognize'
    # Request data from Microsoft
    faceEMO = POST(
      url = emotion_url,
      content_type('application/json'), add_headers(.headers = c('Ocp-Apim-Subscription-Key' = emotion_key)),
      body = mybody,
      encode = 'json'
    )
    # Request results
    emotion_results = httr::content(faceEMO)[[1]]
    # Transform and prepare the results
    df_emotion_results = as.data.frame(as.matrix(emotion_results$scores))
    df_emotion_results$V1 = as.numeric(df_emotion_results$V1)*100
    colnames(df_emotion_results)[1] = "Level"
    df_emotion_results$Emotion = rownames(df_emotion_results)
    
    ##### Face API
    # Define Microsoft API URL to request data
    face_url = "https://api.projectoxford.ai/face/v1.0/detect?returnFaceId=true&returnFaceLandmarks=true&returnFaceAttributes=age"
    # Request data from Microsoft
    faceResponse = POST(
      url = face_url, 
      content_type('application/json'), add_headers(.headers = c('Ocp-Apim-Subscription-Key' = face_key)),
      body = mybody,
      encode = 'json'
    )
    # Request results
    face_results = httr::content(faceResponse)[[1]]

    ##### Plots
    ### Plot emotion barchart with the age variable as title and the picture itself, delete the picture afterwards
    # Plot the predicted data
    ggplot(data = df_emotion_results, aes(x = Emotion, y = Level, fill = Emotion)) +
      geom_bar(stat = 'identity') + 
      ylab('%') +
      theme(plot.title = element_text(hjust = 0.5)) +
      theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1))
  })
  output$data = renderTable({
    url = input$url
    emotion_key = 'e84596b3f9b64377904e2e896dde8f42'
    face_key = 'a79c66ae113f44a6857fbf10ba0bede5'
    
    # Define image
    mybody = list(url = url)
    
    ##### Emotion API
    # Define Microsoft API URL to request data
    emotion_url = 'https://api.projectoxford.ai/emotion/v1.0/recognize'
    # Request data from Microsoft
    faceEMO = POST(
      url = emotion_url,
      content_type('application/json'), add_headers(.headers = c('Ocp-Apim-Subscription-Key' = emotion_key)),
      body = mybody,
      encode = 'json'
    )
    # Request results
    emotion_results = httr::content(faceEMO)[[1]]
    # Transform and prepare the results
    df_emotion_results = as.data.frame(as.matrix(emotion_results$scores))
    df_emotion_results$V1 = as.numeric(df_emotion_results$V1)*100
    colnames(df_emotion_results)[1] = "Level"
    df_emotion_results$Emotion = rownames(df_emotion_results)  
    df_emotion_results
  })
  output$age = renderText({
    url = input$url
    ##### Face API
    face_key = 'a79c66ae113f44a6857fbf10ba0bede5'
    # Define image
    mybody = list(url = url)
    # Define Microsoft API URL to request data
    face_url = "https://api.projectoxford.ai/face/v1.0/detect?returnFaceId=true&returnFaceLandmarks=true&returnFaceAttributes=age"
    # Request data from Microsoft
    faceResponse = POST(
      url = face_url, 
      content_type('application/json'), add_headers(.headers = c('Ocp-Apim-Subscription-Key' = face_key)),
      body = mybody,
      encode = 'json'
    )
    # Request results
    face_results = httr::content(faceResponse)[[1]]
    # Extract the predicted age & concatenate with a string to serve as a dinamic plot title
    paste('Predicted age:', '', face_results$faceAttributes[[1]])
  })
  
}

shinyApp(ui = ui, server = server)