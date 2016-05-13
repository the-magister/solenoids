
# Serial << F("Available commands:") << endl;
#  Serial << F(" 0;  -> This list.") << endl;
#  Serial << F(" 1,<port>,<delay 1>,<delay N>; -> set port delay timings.") << endl;
#  Serial << F(" 2;  -> show port timings.") << endl;
#  Serial << F(" 3;  -> fire the ports.") << endl;
#  Serial << F(" 4;  -> shutdown the ports.") << endl;
#  Serial << endl;

require(reshape2)
require(ggplot2)
require(ggthemes)
require(dplyr)
require(magrittr)
require(serial)

# port definitions
port.list = c(paste0("AC",0:7), paste0("DC",0:7))

# graphics defaults
theme_set(theme_grey(base_size = 18)) 

# port panel generator
timing.inputs = function(N, name) {
	column(2, wellPanel(
		h4(paste0(name, " (", N, ")")),
		sliderInput(
			inputId=paste0("On.",N), label="On Interval (ms)",
			min=50, max=10000, value=250, step=5
		),
		sliderInput(
			inputId=paste0("Off.",N), label="Off Interval (ms)",
			min=50, max=10000, value=500, step=5
		),
		sliderInput(
			inputId=paste0("Start.",N), label="Start (ms)",
			min=0, max=10000, value=0, step=10
		),
		sliderInput(
			inputId=paste0("Ncycle.",N), label="Number of Cycles",
			min=0, max=20, value=1, step=1
		)
	))
}

# port timing UI
port.timings = function(ports, port.names) {
	ret = tagList()
	
	for( i in 1:length(ports) ) {
		ret = tagList(ret,
			timing.inputs(ports[i], port.names[i])
		)
	}
	ret = fluidRow(ret) 

	return( ret )
}

# port naming UI
port.naming = function(ports) {
	ret = tagList()
	for( p in ports ) {
		ret = tagList(ret,
			textInput(paste0("port.name.",p), paste0(p, " name:"), value=p)
		)
	}
	return( ret )
}

# timing generation
generate.timings = function(On, Off, Start, N) {

	if(N<1) return( data.frame(Duration=NULL, Time=NULL) )
	
	tim = NULL
	if( Start > 0 ) {
		tim = data.frame(Duration=c(0,Start), Time=c(0,Start))
	}
	
	tnow = Start
	for( i in 1:N ) {
		tim = rbind(tim, data.frame(
			Duration=c(On, Off),
			Time=c(tnow+On, tnow+On+Off)
		))
		tnow=tnow+On+Off
	}
	
	tim = slice(tim, 1:(n()-1))
	
	return( tim )
}

serial.send = function(send) {
	if( !serial.open ) return( "(no Serial opened)" )
	if( !isOpen(serialCon) ) return( "(no Serial opened)" )
	
	write.serialConnection(serialCon, send)
	Sys.sleep(0.5)
	ret = paste0("", read.serialConnection(serialCon))
	return( ret )
}

port.names = NULL
serialCon = NULL
serial.open = FALSE
# track what's been sent
send.clear.last = 0
send.timing.last = 0
send.show.last = 0
send.fire.last = 0
send.abort.last = 0

# punch out the required serial commands
send.timing = function(tt) {
	cmd = tt %>%
		rowwise %>%
		do( {
			if( .$N<1 ) return( data.frame(cmd="") )
			port = which(.$Port==port.list)-1
			return( data_frame(
				cmd=paste0(paste("2", port, .$On, .$Off, .$N, .$Start, sep=","),";")
			))
		} ) %>% 
		ungroup
		
	return(paste0(cmd$cmd, collapse=""))
}

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {

	### Ports tab
	# let the user select the active ports
	active.ports = reactive({ 
		ports = input$ports
		cat(file=stderr(), "active ports:", ports, "\n")
		return( ports )
	})
	# generate a UI for naming those active ports
	output$port.naming = renderUI({ port.naming(active.ports()) })
	# read back in the active port names
	observe({ 
		port.names <<- NULL
		for( p in active.ports() ) {
			port.names <<- c(port.names,
				input[[paste0("port.name.",p)]]
			)
		}
		cat(file=stderr(), "port names:", port.names, "\n")
	})
	# update the serial options
	observe({
		cons = grep("COM",listPorts(),val=T)
		updateSelectizeInput(session, "serial", choices=c("(none)",cons))
		cat(file=stderr(), "serial port options:", cons, "\n")
	})
	# define the serial connection
	serial.sel = reactive({
		cat(file=stderr(), "serial port selected:", input$serial, "\n")
		if( serial.open ) { 
			if(isOpen(serialCon)) { 
				close(serialCon) 
			} 
			serial.open <<- FALSE
		}
		if( input$serial != "(none)" ) {
			serialCon <<- serialConnection(name="com", port=input$serial)
			serial.open <<- FALSE
			cat(file=stderr(), "opening serial port:", input$serial, "\n")
		}
		input$serial
	})
	# make sure to close it on exit
	cancel.onSessionEnded = session$onSessionEnded(function(){
		if( serial.open ) { 
			if(isOpen(serialCon)) { 
				close(serialCon) 
			} 
		}
	})
	# show the output
	output$serialResponse = renderPrint({
		cat("Serial monitor\n")
		if( serial.sel() == "(none)" ) {
			cat( "Waiting for Serial port selection (idle)\n" )
		} else {
			o.opening = sprintf("Opening Port: %s\n", serial.sel())
			open(serialCon)
			serial.open <<- isOpen(serialCon)
			o.succ = sprintf("Successfully opened? %s\n",ifelse(serial.open,"true","false"))
			Sys.sleep(1)
			serial.send("0;")
			Sys.sleep(0.25)
			o.text = read.serialConnection(serialCon)
			cat(file=stderr(), "serial port opening response:", o.text, "\n")

			cat(paste0(o.opening, o.succ, o.text))
		}
	})

	### Timings tab
	output$port.timing = renderUI({ port.timings(active.ports(), port.names) })
	timing.table = reactive({
		dt = NULL
		for( p in active.ports() ) {
			dt = rbind(dt,
				data.frame(
					Port=p,
					Name=port.names[active.ports() %in% p ],
					On=input[[paste0("On.",p)]],
					Off=input[[paste0("Off.",p)]],
					Start=input[[paste0("Start.",p)]],
					N=input[[paste0("Ncycle.",p)]]
				)
			)
		}	
		return( dt )
		
	})
	output$visualize = renderPlot({ 
		if(nrow(timing.table())==0) return( ggplot() )
	
		to.uC = timing.table() %>%
			group_by( Port, Name ) %>%
		#	do( with(., slice(generate.timings(On, Off, Start, N), 1:(n()-1)) ) ) %>%
			do( with(., generate.timings(On, Off, Start, N) ) ) %>%
			ungroup %>%
			data.frame
		
		# augment the uC timing table for humans
		to.display = to.uC %>%
			group_by(Port, Name) %>%
			do( {
				ret = with(., rbind(data.frame(Port=Port[1], Name=Name[1], Duration=0, Time=0), .) ) %>%
					mutate( 
						State=c(rep(c("On","Off"), nrow(.)/2)),
						Label=paste0(Name, " (", Port, ")")
					)
				return( ret )
			} )
		
		ggplot(to.display) +
			aes(x=Time, y=State, color=Label, linetype=Label, group=Label) +
			geom_step() +
			geom_point() +
			scale_color_colorblind() +
			facet_wrap(~Label, ncol=1) +
			scale_x_continuous(breaks=sort(unique(to.display$Time)), minor_breaks=F, name="Time, ms")
	})
	
	### Firing tab
	command.log = reactive({ 
		send.clear.now = input$send.clear
		send.timing.now = input$send.timing
		send.show.now = input$send.show
		send.fire.now = input$send.fire
		send.abort.now = input$send.abort
		
		if( send.clear.now != send.clear.last ) {
			send.clear.last <<- send.clear.now
			cat(file=stderr(), "sending clear\n")
			return( serial.send("1;") )
		}
		if( send.timing.now != send.timing.last ) {
			send.timing.last <<- send.timing.now
			cat(file=stderr(), "sending timing\n")
			timings = send.timing(timing.table())
			timings = paste0("1;", timings, "3;")
			if( fire.with.send() ) timings = paste0(timings, "4;")
			return( serial.send(timings) )
		}
		if( send.show.now != send.show.last ) {
			send.show.last <<- send.show.now
			cat(file=stderr(), "sending show\n")
			return( serial.send("3;") )
			
		}
		if( send.fire.now != send.fire.last ) {
			send.fire.last <<- send.fire.now
			cat(file=stderr(), "sending fire\n")
			return( serial.send("4;") )
		}
		if( send.abort.now != send.abort.last ) {
			send.abort.last <<- send.abort.now
			cat(file=stderr(), "sending abort\n")
			return( serial.send("5;") )
		}
	})
	fire.with.send = reactive({ input$send.fire.with.send })
	
	output$console = renderPrint({
		log = paste0(command.log(), collapse="\\n")
		log = gsub("[\r]","\n", log)
		cat(file=stderr(), "log: ", log, "\n")
		cat( log )
	})
})



	
