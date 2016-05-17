port.list = c(paste0("AC",0:7), paste0("DC",0:7))

# Define UI for application
shinyUI(navbarPage(
	# Application title
	"Solenoid Driver UI",

	# Settings
	tabPanel("Settings",
		fluidRow(
			column(6, wellPanel(
				h4("Active Ports"),
				selectizeInput('ports', 'Select active ports:', choices=port.list, multiple=T, selected="", options=list(maxItems=6)),
				h4("Port Names"),
				uiOutput("port.naming")
			)),
			column(6, wellPanel(
					h4("Timing Settings"),
					sliderInput("maxDur", "Maximum Interval Sizes (ms)", min=50, max=10050, value=1000, step=50)
				),
				wellPanel(
					h4("Serial Connnection"),
					selectizeInput('serial', 'Select serial port:', choices=c("(none)"), multiple=F),
					h4("Serial Response"),
					verbatimTextOutput('serialResponse')
				)
			)			
		)
	),
	
	# Timings
	tabPanel("Timings",
		fluidRow(
			column(12, wellPanel(
				h4("Define Timings"),
				uiOutput("port.timing")
			))
		),
		fluidRow(
			column(12, wellPanel(
				h4("Visualize Timings"),
				plotOutput("visualize")
			))
		)
	),

	# Fire Control
	tabPanel("Firing",
		fluidRow(
			column(4, wellPanel(
				h4("Solenoid Commands"),
				actionButton("send.show", "Show Timings"),
				actionButton("send.clear", "Clear Timing"),
				hr(),
				actionButton("send.timing", "Send Timing"),
				checkboxInput("send.fire.with.send", "Fire After Send?", value=F),
				hr(),
				actionButton("send.fire", "! FIRE !"),
				actionButton("send.abort", "! ABORT !")
			)),
			column(8, wellPanel(
				h4("µController Output"),
				verbatimTextOutput('console')
			))
		)
	)

))

