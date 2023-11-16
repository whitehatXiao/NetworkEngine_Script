# $language = "VBScript"
# $interface = "1.0"

' ImportArbitraryDataFromFileToSecureCRTSessions.txt
'   (Designed for use with SecureCRT 7.2 and later)
'
'   Last Modified: 29 Oct, 2018
'      - Change behavior to prompt individuals if they want new
'        session settings to derive from the "Default" session or
'        use this script's customizations.
'
'   Last Modified: 19 Jul, 2018
'      - As some may have modified the Default session's protocol to
'        something incompatible with various options, the defaulting of
'        some options for imported sessions is now wrapped in error
'        suppressing tags to avoid the script bombing out if the default
'        session isn't SSH1/SSH2.
'      - This script example no longer enables templated log file naming
'        for imported sessions. This default behavior had created some
'        confusion for individuals who had configured their Default
'        session with a templated log file name because the prior version
'        of this script exemplified setting the value of the log file
'        name field for imported sessions to a templated log file name
'        that was different from what the individual had set in the Default
'        session. The code is still present, but it is commented out.
'        Search below for "Log Filename V2" if you want to see where to re-
'        enable it for your specific import objectives.
'
'   Last Modified: 25 Apr, 2018
'      - Folder and session names are now validated more rigorously so
'        that reserved keywords don't result in the script bailing out
'        part way through an import on Windows (CON, PRN, AUX, NUL,
'        COM1, LPT1, etc.)
'      - Implement default settings for imported sessions to exemplify
'        how this can be done (Auto-reconnect, Anti-idle, Log file
'        templated params, Word delims, Scrollback buffer size > 500,
'        etc.)
'
'   Last Modified: 23 Feb, 2018
'      - Warn user if the configuration folder appears to be read-only.
'      - Fall back to secondary locations in which to attempt to write
'        the results log file in case the user's Documents, Desktop, or
'        configuration folder are all read-only or otherwise un-write-able
'        for the user.
'
'   Last Modified: 21 Dec, 2017
'      - Allow multiple 'description' fields on the same line. All will be
'        compounded together with each one ending up on a separate line in
'        the Session's Description session option.
'      - Allow 'username' field to be defaulted in the header line
'      - Allow 'folder' field to be defaulted in the header line
'      - Duplicate sessions are now imported with unique time-stamped
'        names (for each additional duplicate). Earlier versions of this
'        script would overwrite the first duplicate with any subsequent
'        duplicates that were found in the data file.
'      - When displaying the browse dialog, filter now includes both
'        CSV and TXT file types, to make it easier to find the data file
'        (less clicking).
'      - Allow for protocol field to be defaulted, if not present in the
'        header line.
'      - Fix error messages relating to invalid header lines so they no
'        longer indicate Protocol is a required field. If it's not present
'        the Default Session's protocol value will be used.
'      - Allow header fields to be case-insensitive so that "Description"
'        and "UserName" work just the same as "description" and "username"
'
'   Last Modified: 09 Aug, 2017
'      - Changed from using CInt to CLng in order to support port
'        specifications larger than 32768 (max integer supported in VBScript)
'
'   Last Modified: 20 Feb, 2017
'      - Added progress info to status bar
'      - When a line from the source file has bogus/incomplete data on it,
'        the script no longer halts operation, but instead, continues the
'        import process for all remaining legitimate lines, skipping any
'        lines that don't have sufficient/accurate format.
'      - Changed format of summary message shown at end to include header
'        line so entries that were skipped can be easily copied into a new
'        document to be imported.
'      - Toggle the Session Manager automatically so that imported sessions
'        are more immediately visible in the Session Manager.
'
'   Last Modified: 20 Jan, 2015
'      - Combined TAPI protocol handling (which is no longer
'        supported for mass import) with Serial protocol
'        import errors.
'      - Enhanced example .csv file data to show subfolder specification.
'
'   Last Modified: 21 Mar, 2012
'      - Initial version for public forums
'
' DESCRIPTION
' This sample script is designed to create sessions from a text file (.csv
' format by default, but this can be edited to fit the format you have).
'
' To launch this script, map a button on the button bar to run this script:
'    http://www.vandyke.com/support/tips/buttonbar.html
'
' The first line of your data file should contain a comma-separated (or whatever
' you define as the g_strDelimiter below) list of supported "fields" designated
' by the following keywords:
' -----------------------------------------------------------------------------
' session_name: The name that should be used for the session. If this field
'               does not exist, the hostname field is used as the session_name.
'       folder: Relative path for session as displayed in the Connect dialog.
'     hostname: The hostname or IP for the remote server.
'     protocol: The protocol (SSH2, SSH1, telnet, rlogin)
'         port: The port on which remote server is listening
'     username: The username for the account on the remote server
'    emulation: The emulation (vt100, xterm, etc.)
'  description: The comment/description. Multiple lines are separated with '\r'
' =============================================================================
'
'
' As mentioned above, the first line of the data file instructs this script as
' to the format of the fields in your data file and their meaning.  It is not a
' requirement that all the options be used. For example, notice the first line
' of the following file only uses the "hostname", "username", and "protocol"
' fields.  Note also that the "protocol" field can be defaulted so that if a
' protocol field is empty it will use the default value.
' -----------------------------------------------------------------------------
'   hostname,username,folder,protocol=SSH2
'   192.168.0.1,root,_imported,SSH1
'   192.168.0.2,admin,_imported,SSH2
'   192.168.0.3,root,_imported\folderA,
'   192.168.0.4,root,,
'   192.168.0.5,admin,_imported\folderB,telnet
'   ... and so on
' =============================================================================
'
'
' The g_strDefaultProtocol variable will only be defined within the
' ValidateFieldDesignations function if the protocol field has a default value
' (e.g., protocol=SSH2), as read in from the first line of the data file.
Dim g_strDefaultProtocol

' The g_strDefaultFolder variable will only be defined within the
' ValidateFieldDesignations function if the folder field has a default value
' (e.g., folder=Site34), as read in from the first line of the data file.
Dim g_strDefaultFolder

' The g_strDefaultUsername variable will only be defined within the
' ValidateFieldDesignations function if the username field has a default value
' (e.g., username=bensolo), as read in from the first line of the data file.
Dim g_strDefaultUsername

' If your data file uses spaces or a character other than comma as the
' delimiter, you would also need to edit the g_strDelimiter value a few lines
' below to indicate that fields are separated by spaces, rather than by commas.
' For example:
'   g_strDelimiter = " "

' Using a ";" might be a good alternative for a file that includes the comma
' character as part of any legitimate session name or folder name, etc.
Dim g_strDelimiter
g_strDelimiter = ","      ' comma
' g_strDelimiter = " "    ' space
' g_strDelimiter = ";"    ' semi-colon
' g_strDelimiter = chr(9) ' tab
' g_strDelimiter = "|||"  ' a more unique example of a delimiter.

' The g_strSupportedFields indicates which of all the possible fields, are
' supported in this example script.  If a field designation is found in a data
' file that is not listed in this variable, it will not be imported into the
' session configuration.
Dim g_strSupportedFields
g_strSupportedFields = _
    "description,emulation,folder,hostname,port,protocol,session_name,username"

' If you wish to overwrite existing sessions, set the
' g_bOverwriteExistingSessions to True; for this example script, we're playing
' it safe and leaving any existing sessions in place :).
Dim g_bOverwriteExistingSessions
g_bOverwriteExistingSessions = False

Dim g_fso, g_shell
Set g_fso = CreateObject("Scripting.FileSystemObject")
Set g_shell = CreateObject("WScript.Shell")

Const ForReading = 1
Const ForWriting = 2
Const ForAppending = 8

Dim g_strHostsFile, g_strExampleHostsFile, g_strMyDocs, g_strMyDesktop
g_strMyDocs = g_shell.SpecialFolders("MyDocuments")
g_strMyDesktop = g_shell.SpecialFolders("Desktop")
g_strHostsFile = g_strMyDocs & "\MyDataFile.csv"
g_strExampleHostsFile = _
    vbtab & "hostname,protocol,username,folder,emulation" & vbcrlf & _
    vbtab & "192.168.0.1,SSH2,root,Linux Machines,XTerm" & vbcrlf & _
    vbtab & "192.168.0.2,SSH2,root,Linux Machines,XTerm" & vbcrlf & _
    vbtab & "..." & vbcrlf & _
    vbtab & "10.0.100.1,SSH1,admin,CISCO Routers,VT100" & vbcrlf & _
    vbtab & "10.0.101.1,SSH1,admin,CISCO Routers,VT100" & vbcrlf & _
    vbtab & "..." & vbcrlf & _
    vbtab & "myhost.domain.com,SSH2,administrator,Windows Servers,VShell" & _
    vbtab & "..." & vbcrlf
g_strExampleHostsFile = Replace(g_strExampleHostsFile, ",", g_strDelimiter)

Dim g_strConfigFolder, strFieldDesignations, vFieldsArray, vSessionInfo

g_strConfigFolder = GetConfigPath()

Dim strSessionName, strHostName, strPort
Dim strUserName, strProtocol, strEmulation
Dim strPathForSessions, g_strLine, nFieldIndex
Dim strSessionFileName, strFolder, nDescriptionLineCount, strDescription

Dim g_strLastError, g_strErrors, g_strSessionsCreated
Dim g_nSessionsCreated, g_nDataLines
Dim g_nCurLineNumber

Dim g_bUseDefaultSessionOptions
g_bUseDefaultSessionOptions = True

g_strDateTimeTag = GetDateTimeTag()

g_strBogusLinesNotImported = ""

Import

'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Sub Import()

    g_strHostsFile = crt.Dialog.FileOpenDialog( _
        "Please select the host data file to be imported.", _
        "Open", _
        g_strHostsFile, _
        "CSV/Text Files (*.txt;*.csv)|*.txt;*.csv|All files (*.*)|*.*")

    If g_strHostsFile = "" Then
        Exit Sub
    End If

    ' Open our data file for reading
    Dim objDataFile
    Set objDataFile = g_fso.OpenTextFile(g_strHostsFile, ForReading, False)

    ' Now read the first line of the data file to determine the field
    ' designations
    On Error Resume Next
    strFieldDesignations = objDataFile.ReadLine()
    nError = Err.Number
    strErr = Err.Description
    On Error Goto 0

    If nError <> 0 Then
        If nError = 62 Then
            crt.Dialog.MessageBox("Your data file is empty." & vbcrlf & _
                "Fill it with import data and try again." & vbcrlf & vbcrlf & _
                "ReadLine() Error code: " & nError & vbcrlf & _
                "ReadLine() Error text: " & strErr)
        Else
            crt.Dialog.MessageBox("Unable to read the first line from your data file!" & _
                vbcrlf & vbcrlf & _
                "ReadLine() Error code: " & nError & vbcrlf & vbcrlf & _
                "ReadLine() Error text: " & strErr)
        End If
        Exit Sub
    End If

    ' Validate the data file
    If Not ValidateFieldDesignations(strFieldDesignations) Then
        objDataFile.Close
        Exit Sub
    End If

    ' Ask user if they want default settings for imported sessions to derive
    ' values from the "Default" session, or use this script's defaults.
    nResult = crt.Dialog.MessageBox("" & _
        "For new sessions created by this script..." & vbcrlf & vbcrlf & _
        "Use settings from the ""Default"" session?" & _
        vbcrlf & _
        vbtab & "Or..." & vbcrlf & _
        "Use this script's customized options?" & vbcrlf & _
        "   (see lines 612-659 in the script code for options & values)" & _
        vbcrlf & _
        "__________________________________________________" & vbcrlf & _
        vbcrlf & _
        "Yes:" & vbTab & "Use ""Default"" Session options." & vbcrlf & _
        "No:" & vbtab & "Use custom options defined in this script." & _
        vbcrlf & _
        "Cancel: " & vbtab & "Exit script; let me read/modify the " & _
            "code before I decide.", _
        "Use ""Default"" Session options for imported sessions?", _
        3)

    Select Case nResult
        Case 6 ' Yes:
            g_bUseDefaultSessionOptions = True

        Case 7 ' No:
            g_bUseDefaultSessionOptions = False

        Case 2 ' Cancel:
            Exit Sub
    End Select

    ' Get a timer reading so that we can calculate how long it takes to import.
    nStartTime = Timer

    ' Here we create an array of the items that will be used to create the new
    ' session, based on the fields separated by the delimiter specified in
    ' g_strDelimiter
    vFieldsArray = Split(strFieldDesignations, g_strDelimiter)

    ' Loop through reading each line in the data file and creating a session
    ' based on the information contained on each line.
    Do While Not objDataFile.AtEndOfStream
        g_strLine = ""
        g_strLine = objDataFile.ReadLine
        g_nCurLineNumber = NN(objDataFile.Line - 1, 4)
        crt.Session.SetStatusText "Processing line #: " & _
                g_nCurLineNumber

        ' This sets v_File Data array elements to each section of g_strLine,
        ' separated by the delimiter
        vSessionInfo = Split(g_strLine, g_strDelimiter)
        If UBound(vSessionInfo) < UBound(vFieldsArray) Then
            If Trim(g_strLine) <> "" Then
                g_strErrors = g_strErrors & vbcrlf & _
                    "Insufficient data on line #" & _
                    g_nCurLineNumber & ": " & g_strLine
            Else
                g_strErrors = g_strErrors & vbcrlf & _
                    "Insufficient data on line #" & _
                    g_nCurLineNumber & ": [Empty Line]"
            End If
        ElseIf UBound(vSessionInfo) > UBound(vFieldsArray) Then
            g_strErrors = g_strErrors & vbcrlf & _
                "==> Number of data fields on line #" & _
                g_nCurLineNumber & _
                " (" & UBound(vSessionInfo) + 1 & ") " & _
                "does not match the number of fields in the header " & _
                "(" & UBound(vFieldsArray) + 1 & ")." & vbcrlf & _
                    "    This line will not be imported (Does the session name have a character that " & _
                    "matches the delimiter you're using?): " & vbcrlf & vbtab & g_strLine
            g_strBogusLinesNotImported = g_strBogusLinesNotImported & _
                vbcrlf & g_strLine
        Else

            ' Variable used to determine if a session file should actually be
            ' created, or if there was an unrecoverable error (and the session
            ' should be skipped).
            Dim bSaveSession
            bSaveSession = True

            ' Now we will match the items from the new file array to the correct
            ' variable for the session's ini file
            For nFieldIndex = 0 To UBound(vSessionInfo)

                Select Case LCase(vFieldsArray(nFieldIndex))
                    Case "session_name"
                        strSessionName = vSessionInfo(nFieldIndex)

                    Case "port"
                        strPort = Trim(vSessionInfo(nFieldIndex))
                        If Not IsNumeric(strPort) Then
                            bSaveSession = False
                            If g_strErrors <> "" Then g_strErrors = _
                                vbcrlf & g_strErrors

                            g_strErrors = _
                                "Error: Invalid port """ & strPort & _
                                """ specified on line #" & _
                                g_nCurLineNumber & _
                                ": " & g_strLine & g_strErrors

                            g_strBogusLinesNotImported = g_strBogusLinesNotImported & _
                                vbcrlf & g_strLine
                        End If

                    Case "protocol"
                        strProtocol = Trim(lcase(vSessionInfo(nFieldIndex)))

                        Select Case strProtocol
                            Case "ssh2"
                                strProtocol = "SSH2"
                            Case "ssh1"
                                strProtocol = "SSH1"
                            Case "telnet"
                                strProtocol = "Telnet"
                            Case "serial", "tapi"
                                bSaveSession = False
                                g_strErrors = g_strErrors & vbcrlf & _
                                    "Error: Unsupported protocol """ & _
                                    vSessionInfo(nFieldIndex) & _
                                    """ specified on line #" & _
                                    g_nCurLineNumber & _
                                    ": " & g_strLine
                            Case "rlogin"
                                strProtocol = "RLogin"
                            Case Else
                                If g_strDefaultProtocol <> "" Then
                                    strProtocol = g_strDefaultProtocol
                                Else
                                    bSaveSession = False
                                    If g_strErrors <> "" Then g_strErrors = _
                                        vbcrlf & g_strErrors

                                    g_strErrors = _
                                        "Error: Invalid protocol """ & _
                                        vSessionInfo(nFieldIndex) & _
                                        """ specified on line #" & _
                                        g_nCurLineNumber & _
                                        ": " & g_strLine & g_strErrors

                                    g_strBogusLinesNotImported = g_strBogusLinesNotImported & _
                                        vbcrlf & g_strLine
                                End If
                        End Select ' for protocols

                    Case "hostname"
                        strHostName = Trim(vSessionInfo(nFieldIndex))
                        If strHostName = "" Then
                            bSaveSession = False
                            g_strErrors = g_strErrors & vbcrlf & _
                                "Warning: 'hostname' field on line #" & _
                                g_nCurLineNumber & _
                                " is empty: " & g_strLine

                            g_strBogusLinesNotImported = g_strBogusLinesNotImported & _
                                vbcrlf & g_strLine
                        End If

                    Case "username"
                        strUserName = Trim(vSessionInfo(nFieldIndex))

                    Case "emulation"
                        strEmulation = LCase(Trim(vSessionInfo(nFieldIndex)))
                        Select Case strEmulation
                            Case "xterm"
                                strEmulation = "Xterm"
                            Case "vt100"
                                strEmulation = "VT100"
                            Case "vt102"
                                strEmulation = "VT102"
                            Case "vt220"
                                strEmulation = "VT220"
                            Case "ansi"
                                strEmulation = "ANSI"
                            Case "linux"
                                strEmulation = "Linux"
                            Case "scoansi"
                                strEmulation = "SCOANSI"
                            Case "vshell"
                                strEmulation = "VShell"
                            Case "wyse50"
                                strEmulation = "WYSE50"
                            Case "wyse60"
                                strEmulation = "WYSE60"
                            Case Else
                                bSaveSession = False
                                g_strErrors = g_strErrors & vbcrlf & _
                                    "Warning: Invalid emulation """ & _
                                    strEmulation & """ specified on line #" & _
                                    g_nCurLineNumber & _
                                    ": " & g_strLine

                                g_strBogusLinesNotImported = g_strBogusLinesNotImported & _
                                    vbcrlf & g_strLine
                        End Select

                    Case "folder"
                        strFolder = Trim(vSessionInfo(nFieldIndex))

                    Case "description"
                        strCurDescription = Trim(vSessionInfo(nFieldIndex))
                        If strDescription = "" Then
                            strDescription = strCurDescription
                        Else
                            strDescription = strDescription & "\r" & strCurDescription
                        End If

                    Case Else
                        ' If there is an entry that the script is not set to use
                        ' in strFieldDesignations, stop the script and display a
                        ' message
                        Dim strMsg1
                        strMsg1 = "Error: Unknown field designation: " & _
                            vFieldsArray(nFieldIndex) & vbcrlf & vbcrlf & _
                            "       Supported fields are as follows: " & _
                            vbcrlf & vbcrlf & vbtab & g_strSupportedFields & _
                            vbcrlf & _
                            vbcrlf & "       For a description of " & _
                            "supported fields, please see the comments in " & _
                            "the sample script file."

                        If Trim(g_strErrors) <> "" Then
                            strMsg1 = strMsg1 & vbcrlf & vbcrlf & _
                                "Other errors found so far include: " & _
                                g_strErrors
                        End If

                        MsgBox strMsg1, _
                            vbOkOnly, _
                            "Import Data To SecureCRT Sessions: Data File Error"
                        Exit Sub
                End Select
            Next

            ' Use hostname if a session_name field wasn't present
            If strSessionName = "" Then
                strSessionName = strHostName
            End If

            If ValidateSessionFolderComponent(strSessionName, "session") <> True Then bSaveSession = False

            If strFolder = "" Then
                strFolder = g_strDefaultFolder
            End If

            If ValidateSessionFolderComponent(strFolder, "folder") <> True Then bSaveSession = False

            If bSaveSession Then
                ' Canonicalize the path to the session, as needed
                strSessionPath = strSessionName
                If strFolder <> "" Then
                    If Right(strFolder, 1) <> "/" Then
                        strSessionPath = strFolder & "/" & strSessionName
                    Else
                        strSessionPath = strFolder & strSessionName
                    End If
                End If
                ' Strip any leading '/' characters from the session path
                If Left(strSessionPath, 1) = "/" Then
                    strSessionPath = Mid(strSessionPath, 2)
                End If

                If SessionExists(strSessionPath) Then
                    If Not g_bOverwriteExistingSessions Then
                        ' Append a unique tag to the session name, if it already exists
                        strSessionPath = strSessionPath & _
                            "(import_" & GetDateTimeTag & ")"
                    End If
                End If

                ' Now: Create the session.

                ' Copy the default session settings into new session name and set the
                ' protocol.  Setting protocol protocol is essential since some variables
                ' within a config are only available with certain protocols.  For example,
                ' a telnet configuration will not be allowed to set any port forwarding
                ' settings since port forwarding settings are specific to SSH.
                Set objConfig = crt.OpenSessionConfiguration("Default")
                If strProtocol = "" Then
                    strProtocol = g_strDefaultProtocol
                End If
                objConfig.SetOption "Protocol Name", strProtocol

                ' We opened a default session & changed the protocol, now we
                ' save the config to the new session path:
                objConfig.Save strSessionPath

                ' Now, let's open the new session configuration we've
                ' saved, and set up the various parameters that were specified
                ' in the file.
                If Not SessionExists(strSessionPath) Then
                    crt.Dialog.MessageBox("Failed to create a new session '" & _
                        strSessionPath & "'." & vbcrlf & _
                        vbcrlf & _
                        "Does your configuration folder have " & _
                        "sufficient permissions to allow writing/creating " & _
                        "files?" & vbcrlf & vbcrlf & _
                        vbtab & _
                        "Options > Global Options > Configuration Paths" & _
                        vbcrlf & vbcrlf & _
                        "Fix permissions on your configuration folder and " & _
                        "then try running this script again.")
                    Exit Sub
                End If
                Set objConfig = crt.OpenSessionConfiguration(strSessionPath)

                objConfig.SetOption "Emulation", strEmulation

                If LCase(strProtocol) <> "serial" Then
                    If strHostName <> "" Then
                        objConfig.SetOption "Hostname", strHostName
                    End If
                    If strUsername = "" Then
                        strUsername = g_strDefaultUsername
                    End If
                    If strUserName <> "" Then
                        objConfig.SetOption "Username", strUserName
                    End If
                End If

                If strDescription <> "" Then
                    objConfig.SetOption "Description", Split(strDescription, "\r")
                End If

                If UCase(strProtocol) = "SSH2" Then
                    If strPort = "" Then strPort = 22
                    objConfig.SetOption "[SSH2] Port", CLng(strPort)
                End If
                If UCase(strProtocol) = "SSH1" Then
                    If strPort = "" Then strPort = 22
                    objConfig.SetOption "[SSH1] Port", CLng(strPort)
                End If
                If UCase(strProtocol) = "TELNET" Then
                    If strPort = "" Then strPort = 23
                    objConfig.SetOption "Port", CLng(strPort)
                End If

                ' Only enter this next block if the individual decided to
                ' use this script's settings, not "Default" session's values.
                If Not g_bUseDefaultSessionOptions Then
                    On Error Resume Next
                    ' If you want ANSI Color enabled for all imported sessions (regardless
                    ' of value in Default session, un-comment the following 3 lines)
                    ' ---------------------------------------------------------------------------
                    objConfig.SetOption "ANSI Color", True
                    objConfig.SetOption "Color Scheme", "Solarized Darcula" ' Requires 8.3 or newer
                    objConfig.SetOption "Color Scheme Overrides Ansi Color", True

                    ' Additional "SetOption" calls desired here... un-comment those you want, and
                    ' add more lines for other options you desire to be set by default for all
                    ' sessions created from the import operation. Note: ${VDS_USER_DATA_PATH} is
                    ' a cross-platform representation of the current user's "Documents" folder on
                    ' every platform except for Linux versions of SecureCRT (in which case, it
                    ' represents the user's home folder)
                    ' ---------------------------------------------------------------------------

                    objConfig.SetOption "Auto Reconnect", True
                    objConfig.SetOption "Idle NO-OP Check", True
                    objConfig.SetOption "Idle NO-OP Timeout", 60

                    ' If you desire templated log file naming to be on for all imported sessions,
                    ' uncomment out the following 4 lines of code:
                    Set objDefaultConfig = crt.OpenSessionConfiguration("Default")
                    If objDefaultconfig.GetOption("Log Filename V2") = "" Then
                        objConfig.SetOption "Log Filename V2", "${VDS_USER_DATA_PATH}\_ScrtLog\%F\(%S)_%Y%M%D_%h%m%s.%t.txt"
                    End If
                    'objConfig.SetOption "Start Log Upon Connect", False
                    objConfig.SetOption "Rows", 60
                    objConfig.SetOption "Cols", 140
                    If objConfig.GetOption("Word Delimiter Chars") = "" Then
                        ' Only apply word delim chars if the
                        ' default session didn't have any set.
                        objConfig.SetOption "Use Word Delimiter Chars", True
                        objConfig.SetOption "Word Delimiter Chars", " <>()+=$%!#*"
                    End If

                    objConfig.SetOption "Key Exchange Algorithms", "diffie-hellman-group-exchange-sha256,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group-exchange-sha1,diffie-hellman-group14-sha1,diffie-hellman-group1-sha1"
                    objConfig.SetOption "Ignore Window Title Change Requests", True
                    If objConfig.GetOption("Scrollback") = "500" Then
                        ' Only modify the default scrollback
                        ' buffer if it's at the default (low)
                        ' 500 setting
                        objConfig.SetOption "Scrollback", 12345
                    End If
                    ' objConfig.SetOption "SSH2 Authentications V2", "publickey,keyboard-interactive,password"
                    ' objConfig.SetOption "Identity Filename V2", "${VDS_USER_DATA_PATH}\Identity"
                    ' objConfig.SetOption "Keyword Set", "MyCiscoKeywords"
                    ' objConfig.SetOption "Highlight Color", True
                    ' objConfig.SetOption "Highlight Reverse Video", True
                    ' objConfig.SetOption "Firewall Name", "Session:JumpHost"
                    ' objConfig.SetOption "Firewall Name", "GlobalOptionDefinedFirewallName"
                    objConfig.SetOption "Auth Prompts in Window", True
                    '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    On Error Goto 0
                End If

                objConfig.Save

                If g_strSessionsCreated <> "" Then
                    g_strSessionsCreated = g_strSessionsCreated & vbcrlf
                End If
                g_strSessionsCreated = g_strSessionsCreated & "    " & strSessionPath

                g_nSessionsCreated = g_nSessionsCreated + 1

            End If

            ' Reset all variables in preparation for reading in the next line of
            ' the hosts info file.
            strEmulation = ""
            strPort = ""
            strHostName = ""
            strFolder = ""
            strUserName = ""
            strSessionName = ""
            strDescription = ""
            nDescriptionLineCount = 0
        End If

    Loop

    g_nDataLines = objDataFile.Line
    objDataFile.Close

    crt.Session.SetStatusText ""

    Dim strResults
    strResults = "Import operation completed in " & _
        GetMinutesAndSeconds(Timer - nStartTime)

    If g_nSessionsCreated > 0 Then
        strResults = strResults & _
            vbcrlf & _
            String(70, "-") & vbcrlf & _
            "Number of Sessions created: " & g_nSessionsCreated & vbcrlf & _
            vbcrlf & _
            g_strSessionsCreated
    Else
        strResults = strResults & vbcrlf & _
            String(70, "-") & vbcrlf & _
            "No sessions were created from " & g_nDataLines & " lines of data."
    End If

    If g_strErrors = "" Then
        strResults = "No errors/warnings encountered from the import operation." & vbcrlf & vbcrlf & strResults
    Else
        strResults = "Errors/warnings from this operation include: " & vbcrlf & g_strErrors & vbcrlf & _
            String(70, "-") & vbcrlf & _
            strResults
    End If

    If g_strBogusLinesNotImported <> "" Then
        strResults = _
            "The following lines from the data file were *not* imported for " & _
            "various reasons detailed below:" & vbcrlf & _
            String(70, "=") & vbcrlf & _
            strFieldDesignations & _
            g_strBogusLinesNotImported & vbcrlf & _
            String(70, "-") & vbcrlf & _
            "Fix the above lines to resolve the issues and save the fixed lines " & _
            "to a new file. You can then run this script again to import these " & _
            "skipped sessions." & vbcrlf & vbcrlf & strResults
    End If


    Set cFilenames = CreateObject("Scripting.Dictionary")
    cFilenames.Add Replace(g_strMyDocs & "/__SecureCRT-Session-ImportLog-" & g_strDateTimeTag & ".txt", "\", "/"), ""
    cFilenames.Add Replace(g_strMyDesktop & "/__SecureCRT-Session-ImportLog-" & g_strDateTimeTag & ".txt", "\", "/"), ""
    cFilenames.Add Replace(g_strConfigFolder & "/__SecureCRT-Session-ImportLog-" & g_strDateTimeTag & ".txt", "\", "/"), ""

    bSuccess = False

    strResults = strResults & vbcrlf & vbcrlf & _
        String(80, "-") & vbcrlf

    For Each strFilename In cFilenames.Keys():
        On Error Resume Next
        Set objFile = g_fso.OpenTextFile(strFilename, ForWriting, True)
        strErr = Err.Description
        nError = Err.Number
        On Error Goto 0
        If nError = 0 Then
            bSuccess = True
            Exit For
        Else
            crt.Session.SetStatusText("Unable to open results file.")
            strResults = strResults & vbcrlf & _
                "Failed to write summary results to: " & strFilename
        End If

        If Not g_fso.FileExists(strFilename) Then
            bSuccess = False
        Else
            Exit For
        End If
    Next

    If Not bSuccess Then
        crt.Clipboard.Text = strResults
        crt.Dialog.MessageBox( _
            "Attempted to write summary results to the file locations below, " & _
            "but access was denied." & vbcrlf & vbtab & vbcrlf & vbtab & _
            Join(cFilenames.Keys(), vbcrlf & vbtab) & vbcrlf & vbcrlf & _
            "Results are in the clipboard. " & _
            "Paste this data into your favorite app now to see what occurred.")
        Exit Sub
    End If

    objFile.WriteLine strResults
    objFile.Close

    ' Display the log file as an indication that the information has been
    ' imported.
    g_shell.Run chr(34) & strFilename & chr(34), 5, False
End Sub

'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
'      Helper Methods and Functions
'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Function ValidateSessionFolderComponent(strComponent, strType)
' strType can be either:
'    folder
'    session
    strOrigComponent = strComponent
    strType = LCase(strType)

    ' Check strComponent name for any invalid characters
    Set re = New RegExp
    If strType = "folder" Then
        ' Folders as specified in the data file can have
        ' / chars since they can include sub-folder components.
        re.Pattern = "([\|\:\*\?\""\<\>])"
    Else
        ' Session names cannot have a / chars
        re.Pattern = "([\|\:\*\?\""\<\>/])"
    End If

    If re.Test(strComponent) Then
        strOffendingComponent = re.Execute(strComponent)(0).Submatches(0)
        If g_strErrors <> "" Then g_strErrors = _
            vbcrlf & g_strErrors

        g_strErrors = _
            "Error: Invalid character '" & strOffendingComponent & "' in " & strType & " name """ & _
            strOrigComponent & """ specified on line #" & _
            g_nCurLineNumber & _
            ": " & g_strLine & g_strErrors

        g_strBogusLinesNotImported = g_strBogusLinesNotImported & _
            vbcrlf & g_strLine
        ValidateSessionFolderComponent = False
        Exit Function
    End If

    Set reSpecials = New RegExp
    If strType = "folder" Then
        If Left(strComponent, 1) <> "/" Then strComponent = "/" & strComponent
        If Right(strComponent, 1) <> "/" Then strComponent = strComponent & "/"
        reSpecials.Pattern = "/(CON|PRN|AUX|NUL|COM[0-9]|LPT[0-9])/"
    Else
        reSpecials.Pattern = "^(CON|PRN|AUX|NUL|COM[0-9]|LPT[0-9])$"
    End If
    reSpecials.IgnoreCase = True
    If reSpecials.Test(strComponent) Then
        strOffendingComponent = reSpecials.Execute(strComponent)(0).Submatches(0)
        If g_strErrors <> "" Then g_strErrors = _
            vbcrlf & g_strErrors

        g_strErrors = _
            "Error: Invalid " & strType & " name """ & _
            strOrigComponent & """ specified on line #" & _
            g_nCurLineNumber & _
            ": " & g_strLine & " ---> '" & strOffendingComponent & "' is a reserved name on Windows OS." & g_strErrors

        g_strBogusLinesNotImported = g_strBogusLinesNotImported & _
            vbcrlf & g_strLine
        ValidateSessionFolderComponent = False
        Exit Function
    End If

    ValidateSessionFolderComponent = True
End Function

'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Function ValidateFieldDesignations(ByRef strFields)
    If Instr(strFieldDesignations, g_strDelimiter) = 0 Then
        Dim strErrorMsg, strDelimiterDisplay
        strErrorMsg = "Invalid header line in data file. " & _
            "Delimiter character not found: "
        If Len(g_strDelimiter) > 1 Then
            strDelimiterDisplay = g_strDelimiter
        Else
            If Asc(g_strDelimiter) < 33 or Asc(g_strDelimiter) > 126 Then
                strDelimiterDisplay = "ASCII[" & Asc(g_strDelimiter) & "]"
            Else
                strDelimiterDisplay = g_strDelimiter
            End If
        End If
        strErrorMsg = strErrorMsg & strDelimiterDisplay & vbcrlf & vbcrlf & _
            "The first line of the data file is a header line " & _
            "that must include" & vbcrlf & _
            "a '" & strDelimiterDisplay & _
            "' separated list of field keywords." & vbcrlf & _
            vbcrlf & "'hostname' is a required key word." & _
            vbcrlf & vbcrlf & _
            "The remainder of the lines in the file should follow the " & _
            vbcrlf & _
            "pattern established by the header line " & _
            "(first line in the file)." & vbcrlf & "For example:" & vbcrlf & _
            g_strExampleHostsFile
        MsgBox strErrorMsg, _
               vbOkOnly, _
               "Import Data To SecureCRT Sessions"
        Exit Function
    End If

    If Instr(LCase(strFieldDesignations), "hostname") = 0 Then
        strErrorMsg = "Invalid header line in data file. " & _
            "'hostname' field is required."
        If Len(g_strDelimiter) > 1 Then
            strDelimiterDisplay = g_strDelimiter
        Else
            If Asc(g_strDelimiter) < 33 Or Asc(g_strDelimiter) > 126 Then
                strDelimiterDisplay = "ASCII[" & Asc(g_strDelimiter) & "]"
            Else
                strDelimiterDisplay = g_strDelimiter
            End If
        End If

        MsgBox strErrorMsg & vbcrlf & _
            "The first line of the data file is a header line " & _
            "that must include" & vbcrlf & _
            "a '" & strDelimiterDisplay & _
            "' separated list of field keywords." & vbcrlf & _
            vbcrlf & "'hostname' is a required keyword." & _
            vbcrlf & vbcrlf & _
            "The remainder of the lines in the file should follow the " & _
            vbcrlf & _
            "pattern established by the header line " & _
            "(first line in the file)." & vbcrlf & "For example:" & vbcrlf & _
            g_strExampleHostsFile, _
            vbOkOnly, _
            "Import Data To SecureCRT Sessions"
        Exit Function
    End If

    If Instr(LCase(strFieldDesignations), "protocol") = 0 Then
        Set objConfig = crt.OpenSessionConfiguration("Default")
        g_strDefaultProtocol = objConfig.GetOption("Protocol Name")
    Else
        ' We found "protocol", now look for a default protocol designation
        vFields = Split(strFields,g_strDelimiter)
        For each strField In vFields
            If (InStr(LCase(strField), "protocol") > 0) And _
               (Instr(LCase(strField), "=") >0) Then
                    g_strDefaultProtocol = UCase(Split(strField, "=")(1))

                    ' Fix the protocol field since we know the default protocol
                    ' value
                    strFields = Replace(strFields, strField, "protocol")
            End If
        Next
    End If

    vFields = Split(strFields, g_strDelimiter)
    For Each strField In vFields
        If (Instr(LCase(strField), "folder") > 0) And _
           (Instr(LCase(strField), "=") > 0) Then
            g_strDefaultFolder = Split(strField, "=")(1)

            ' Fix the folder field since we know the default folder
            strFields = Replace(strFields, strField, "folder")
        End If

        If (Instr(LCase(strField), "username") > 0) And _
           (Instr(LCase(strField), "=") > 0) Then
           g_strDefaultUsername = Split(strField, "=")(1)

           ' Fix the username field since we know the default username
           strFields = Replace(strFields, strField, "username")
        End If
    Next

    ValidateFieldDesignations = True
End Function

'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Function ReadRegKey(strKeyPath)
    On Error Resume Next
    Err.Clear
    ReadRegKey = g_shell.RegRead(strKeyPath)
    If Err.Number <> 0 Then
        ' Registry key must not have existed.
        ' ReadRegKey will already be empty, but for the sake of clarity, we'll
        ' set it to an empty string explicitly.
        ReadRegKey = ""
    End If
    On Error Goto 0
End Function

'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Function CreateFolderPath(strPath)
' Recursive function
    If g_fso.FolderExists(strPath) Then
        CreateFolderPath = True
        Exit Function
    End If

    ' Check to see if we've reached the drive root
    If Right(strPath, 2) = ":\" Then
        CreateFolderPath = True
        Exit Function
    End If

    ' None of the other two cases were successful, so attempt to create the
    ' folder
    On Error Resume Next
    g_fso.CreateFolder strPath
    nError = Err.Number
    strErr = Err.Description
    On Error Goto 0
    If nError <> 0 Then
        ' Error 76 = Path not found, meaning that the full path doesn't exist.
        ' Call ourselves recursively until all the parent folders have been
        ' created:
        If nError = 76 Then _
            CreateFolderPath(g_fso.GetParentFolderName(strPath))

        On Error Resume Next
        g_fso.CreateFolder strPath
        nError = Err.Number
        strErr = Err.Description
        On Error Goto 0

        ' If the Error is not = 76, then we have to bail since we no longer have
        ' any hope of successfully creating each folder in the tree
        If nError <> 0 Then
            g_strLastError = strErr
            Exit Function
        End If
    End If

    CreateFolderPath = True
End Function

'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Function NN(nNumber, nDesiredDigits)
' Normalizes a number to have a number of zeros in front of it so that the
' total length of the number (displayed as a string) is nDesiredDigits.
    Dim nIndex, nOffbyDigits, strResult
    nOffbyDigits = nDesiredDigits - Len(nNumber)

    NN = nNumber

    If nOffByDigits = 0 Then Exit Function

    If nOffByDigits > 0 Then
        ' The number provided doesn't have enough digits
        strResult = String(nOffbyDigits, "0") & nNumber
    Else
        ' The number provided has too many digits.

        nOffByDigits = Abs(nOffByDigits)

        ' Only remove leading digits if they're all insignificant (0).
        If Left(nNumber, nOffByDigits) = String(nOffByDigits, "0") Then
            strResult = Mid(nNumber, nOffByDigits + 1)
        Else
            ' If leading digits beyond desired number length aren't 0, we'll
            ' return the number as originally passed in.
            strResult = nNumber
        End If
    End If

    NN = strResult
End Function

'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Function GetMinutesAndSeconds(nTotalSecondsElapsed)
    Dim nMinutesElapsed, nSecondsValue, nSecondsElapsed

    If nTotalSecondsElapsed = 0 Then
        GetMinutesAndSeconds = "less than a second."
        Exit Function
    End If

    ' Convert seconds into a fractional minutes value.
    nMinutesElapsed = nTotalSecondsElapsed / 60

    ' Convert the decimal portion into the number of remaining seconds.
    nSecondsValue = nMinutesElapsed - Fix(nMinutesElapsed)
    nSecondsElapsed = Fix(nSecondsValue * 60)

    ' Remove the fraction portion of minutes value, keeping only the digits to
    ' the left of the decimal point.
    nMinutesElapsed = Fix(nMinutesElapsed)

    ' Calculate the number of milliseconds using the four most significant
    ' digits of only the decimal fraction portion of the number of seconds
    ' elapsed.
    nMSeconds = Fix(1000 * (nTotalSecondsElapsed - Fix(nTotalSecondsElapsed)))

    ' Form the final string to be returned and set it as the value of our
    ' function.
    GetMinutesAndSeconds = nMinutesElapsed & " minutes, " & _
        nSecondsElapsed & " seconds, and " & _
        nMSeconds & " ms"
End Function


'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Function SessionExists(strSessionPath)
' Returns True if a session specified as value for strSessionPath already
' exists within the SecureCRT configuration.
' Returns False otherwise.
    On Error Resume Next
    Set objTosserConfig = crt.OpenSessionConfiguration(strSessionPath)
    nError = Err.Number
    strErr = Err.Description
    On Error Goto 0
    ' We only used this to detect an error indicating non-existance of session.
    ' Let's get rid of the reference now since we won't be using it:
    Set objTosserConfig = Nothing
    ' If there wasn't any error opening the session, then it's a 100% indication
    ' that the session named in strSessionPath already exists
    If nError = 0 Then
        SessionExists = True
    Else
        SessionExists = False
    End If
End Function

'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Function GetDateTimeTag()
    ' Use WMI to get at the current time values.  This info will be used
    ' to avoid overwriting existing sessions by naming new sessions with
    ' the current (unique) timestamp.
    Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
    Set colItems = objWMIService.ExecQuery("Select * from Win32_OperatingSystem")
    For Each objItem In colItems
        strLocalDateTime = objItem.LocalDateTime
        Exit For
    Next
    ' strLocalDateTime has the following pattern:
    ' 20111013093717.418000-360   [ That is,  YYYYMMDDHHMMSS.MILLIS(zone) ]
    GetDateTimeTag = Left(strLocalDateTime, 18)
End Function

'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Function GetConfigPath():
    Set objConfig = crt.OpenSessionConfiguration("Default")
    ' Try and get at where the configuration folder is located. To achieve
    ' this goal, we'll use one of SecureCRT's cross-platform path
    ' directives that means "THE path this instance of SecureCRT
    ' is using to load/save its configuration": ${VDS_CONFIG_PATH}.

    ' First, let's use a session setting that we know will do the
    ' translation between the cross-platform moniker ${VDS_CONFIG_PATH}
    ' and the actual value... say, "Upload Directory V2"
    strOptionName = "Upload Directory V2"

    ' Stash the original value, so we can restore it later...
    strOrigValue = objConfig.GetOption(strOptionName)

    ' Now set the value to our moniker...
    objConfig.SetOption strOptionName, "${VDS_CONFIG_PATH}"
    ' Make the change, so that the above templated name will get written
    ' to the config...
    objConfig.Save

    ' Now, load a fresh copy of the config, and pull the option... so
    ' that SecureCRT will convert from the template path value to the
    ' actual path value:
    Set objConfig = crt.OpenSessionConfiguration("Default")
    strConfigPath = objConfig.GetOption(strOptionName)

    ' Now, let's restore the setting to its original value
    objConfig.SetOption strOptionName, strOrigValue
    objConfig.Save

    ' Now return the config path
    GetConfigPath = strConfigPath
End Function
