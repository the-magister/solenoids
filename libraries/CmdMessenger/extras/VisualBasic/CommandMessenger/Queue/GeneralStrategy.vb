#Region "CmdMessenger - MIT - (c) 2013 Thijs Elenbaas."
'
'  CmdMessenger - library that provides command based messaging
'
'  Permission is hereby granted, free of charge, to any person obtaining
'  a copy of this software and associated documentation files (the
'  "Software"), to deal in the Software without restriction, including
'  without limitation the rights to use, copy, modify, merge, publish,
'  distribute, sublicense, and/or sell copies of the Software, and to
'  permit persons to whom the Software is furnished to do so, subject to
'  the following conditions:
'
'  The above copyright notice and this permission notice shall be
'  included in all copies or substantial portions of the Software.
'
'  Copyright 2013 - Thijs Elenbaas
'
#End Region


Imports Microsoft.VisualBasic
Imports System
Namespace CommandMessenger
	''' <summary> Base of general strategy.  </summary>
	Public Class GeneralStrategy
		''' <summary> Gets or sets the command queue. </summary>
		''' <value> A Queue of commands. </value>
		Private privateCommandQueue As ListQueue
		Public Property CommandQueue() As ListQueue(Of CommandStrategy)
			Get
				Return privateCommandQueue
			End Get
			Set(ByVal value As ListQueue)
				privateCommandQueue = value
			End Set
		End Property

		''' <summary> GenerAdd command (strategy) to command queue. </summary>
		Public Overridable Sub OnEnqueue()
		End Sub

		''' <summary> Remove this command (strategy) from command queue. </summary>
		Public Overridable Sub OnDequeue()
		End Sub
	End Class
End Namespace
