# 
#  Copyright 2006 - 2010 Unified EFI, Inc.<BR> 
#  Copyright (c) 2010, Intel Corporation. All rights reserved.<BR>
# 
#  This program and the accompanying materials
#  are licensed and made available under the terms and conditions of the BSD License
#  which accompanies this distribution.  The full text of the license may be found at 
#  http://opensource.org/licenses/bsd-license.php
# 
#  THE PROGRAM IS DISTRIBUTED UNDER THE BSD LICENSE ON AN "AS IS" BASIS,
#  WITHOUT WARRANTIES OR REPRESENTATIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED.
# 
################################################################################
CaseLevel         CONFORMANCE
CaseAttribute     AUTO
CaseVerboseLevel  DEFAULT

#
# test case Name, category, description, GUID...
#
CaseGuid           D2E3225E-AF91-42c5-AFEF-6BB7397D1C65
CaseName           Close.Conf5.Case1
CaseCategory       TCP6
CaseDescription    {This case is to test the conformance - EFI_ACCESS_DENIED.     \
                   -- Close must not succeed when previous close has not finished.}
################################################################################

Include Tcp6/include/Tcp6.inc.tcl

proc CleanUpEUTEnvironmentBegin {} {
  #
  # Destroy TCP6 child
  #
  Tcp6ServiceBinding->DestroyChild "@R_Handle, &@R_Status"
  GetAck
  
  #
  # Close transmittion mechanism for EUT
  #
  EUTClose

}

proc CleanUpEUTEnvironmentEnd {} {

  DestroyPacket
  EndCapture
  EndScope _TCP6_CLOSE_CONF5_CASE1_
  EndLog
}

#
# Begin log ...
#
BeginLog

#
# BeginScope
#
BeginScope _TCP6_CLOSE_CONF5_CASE1_

EUTSetup

#
# Parameter Definition
# R_ represents "Remote EFI Side Parameter"
# L_ represents "Local OS Side Parameter"
#
UINTN                            R_Status
UINTN                            R_Handle
UINTN                            R_Context

EFI_TCP6_ACCESS_POINT            R_Configure_AccessPoint
EFI_TCP6_CONFIG_DATA             R_Configure_Tcp6ConfigData

EFI_TCP6_COMPLETION_TOKEN        R_Connect_CompletionToken
EFI_TCP6_CONNECTION_TOKEN        R_Connect_ConnectionToken

EFI_TCP6_CLOSE_TOKEN             R_Close_CloseToken1
EFI_TCP6_CLOSE_TOKEN             R_Close_CloseToken2
EFI_TCP6_COMPLETION_TOKEN        R_Close_CompletionToken1
EFI_TCP6_COMPLETION_TOKEN        R_Close_CompletionToken2

#
# Create Tcp6 Child.
#
Tcp6ServiceBinding->CreateChild "&@R_Handle, &@R_Status"
GetAck
SetVar     [subst $ENTS_CUR_CHILD]  @R_Handle
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Tcp6SBP.CreateChild - Create Child"                         \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
               
#
# Configure Tcp6 Instance
#
SetIpv6Address  R_Configure_AccessPoint.StationAddress     $DEF_EUT_IP_ADDR
SetVar          R_Configure_AccessPoint.StationPort        $DEF_EUT_PRT
SetIpv6Address  R_Configure_AccessPoint.RemoteAddress      $DEF_ENTS_IP_ADDR
SetVar          R_Configure_AccessPoint.RemotePort         $DEF_ENTS_PRT
SetVar          R_Configure_AccessPoint.ActiveFlag         TRUE


SetVar R_Configure_Tcp6ConfigData.TrafficClass        0
SetVar R_Configure_Tcp6ConfigData.HopLimit           128
SetVar R_Configure_Tcp6ConfigData.AccessPoint         @R_Configure_AccessPoint
SetVar R_Configure_Tcp6ConfigData.ControlOption       0

Tcp6->Configure {&@R_Configure_Tcp6ConfigData, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                \
                "Tcp6.Configure - Call Configure() with valid config data"         \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
# Tcp6.Connect() for an active TCP instance
#
BS->CreateEvent "$EVT_NOTIFY_SIGNAL, $EFI_TPL_CALLBACK, 1, &@R_Context,        \
                 &@R_Connect_CompletionToken.Event, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "BS.CreateEvent."                                              \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

SetVar R_Connect_ConnectionToken.CompletionToken @R_Connect_CompletionToken

#
# Start Capture
#
set L_Filter "ether src $DEF_EUT_MAC_ADDR and tcp"
StartCapture CCB $L_Filter
#
# Setup the packet sending parameters
#
LocalIPv6           $DEF_ENTS_IP_ADDR
RemoteIPv6          $DEF_EUT_IP_ADDR
LocalEther          $DEF_ENTS_MAC_ADDR
RemoteEther         $DEF_EUT_MAC_ADDR

Tcp6->Connect {&@R_Connect_ConnectionToken, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Tcp6.Connect - Open an active connection."      \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
# Handle Three-Way Shake
#

#
# EUT : SYN
#
ReceiveCcbPacket CCB L_Packet 5
if { ${CCB.received} == 0} {    
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                \
                  "TCP6.Connect - No SYN sent."

  BS->CloseEvent {@R_Connect_CompletionToken.Event, &@R_Status}
  GetAck
  CleanUpEUTEnvironmentBegin
  CleanUpEUTEnvironmentEnd
  return
}

ParsePacket L_Packet -t IPv6 -IPv6_payload L_Tcp6Packet
set L_Flag [lrange $L_Tcp6Packet 13 13]
set L_Flag [expr {$L_Flag & 0x37}]
set L_Flag [format "%#04x" $L_Flag]
if {[string compare $L_Flag $SYN] != 0} {
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid  \
                  "Tcp6.Connect -No SYN sent."

  BS->CloseEvent {@R_Connect_CompletionToken.Event, &@R_Status}
  GetAck
  CleanUpEUTEnvironmentBegin
  CleanUpEUTEnvironmentEnd
  return
}
#
# ENTS : SYN | ACK
#
set L_PortDst [lrange $L_Tcp6Packet 0 1]
set L_PortDst [Hex2Dec $L_PortDst]
set L_PortSrc [lrange $L_Tcp6Packet 2 3]
set L_PortSrc [Hex2Dec $L_PortSrc]
set L_Seq     [lrange $L_Tcp6Packet 4 7]
set L_AckAck  [expr {[Hex2Dec $L_Seq]+1}]
set L_Ack     [lrange $L_Tcp6Packet 8 11]
set L_SeqAck  0 
set L_FlagAck [expr {$SYN | $ACK}]

CreatePayload L_TcpOption Data 8 0x02 0x04 0x05 0xa0 0x01 0x03 0x03 0x06
CreatePacket P_Tcp6PacketAck -t tcp -tcp_sp $L_PortSrc -tcp_dp $L_PortDst -tcp_control $L_FlagAck -tcp_seq $L_SeqAck -tcp_options L_TcpOption -IP_ver 0x06 -tcp_ack $L_AckAck
SendPacket P_Tcp6PacketAck -c 1

#
# EUT : ACK
#
ReceiveCcbPacket CCB L_Packet 5
if { ${CCB.received} == 0} {    
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                \
                  "TCP6.Connect - No ACK sent."

  BS->CloseEvent {@R_Connect_CompletionToken.Event, &@R_Status}
  GetAck
  CleanUpEUTEnvironmentBegin
  CleanUpEUTEnvironmentEnd
  return
}

ParsePacket L_Packet -t IPv6 -IPv6_payload L_Tcp6Packet
set L_Flag [lrange $L_Tcp6Packet 13 13]
set L_Flag [expr {$L_Flag & 0x37}]
set L_Flag [format "%#04x" $L_Flag]
if {[string compare $L_Flag $ACK] != 0} {
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid  \
                  "Tcp6.Connect - No ACK sent."

  BS->CloseEvent {@R_Connect_CompletionToken.Event, &@R_Status}
  GetAck
  CleanUpEUTEnvironmentBegin
  CleanUpEUTEnvironmentEnd
  return
}

#
# Check Point: Call Tcp6.Close() to close a connection with valid parameters
#              However, no ack will be sent from ENTS so that the event will 
#              keep unsignaled
#
BS->CreateEvent "$EVT_NOTIFY_SIGNAL, $EFI_TPL_CALLBACK, 1, &@R_Context,        \
                 &@R_Close_CompletionToken1.Event, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "BS.CreateEvent."                                              \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

SetVar R_Close_CompletionToken1.Status  $EFI_INCOMPATIBLE_VERSION
SetVar R_Close_CloseToken1.CompletionToken @R_Close_CompletionToken1
SetVar R_Close_CloseToken1.AbortOnClose   FALSE

Tcp6->Close {&@R_Close_CloseToken1, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                     \
                "Tcp6.Close."                                              \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

ReceiveCcbPacket CCB L_Packet 5
if { ${CCB.received} == 0} {    
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                \
                  "TCP6.Close - No FIN sent."

  BS->CloseEvent {@R_Close_CompletionToken1.Event, &@R_Status}
  GetAck
  BS->CloseEvent {@R_Connect_CompletionToken.Event, &@R_Status}
  GetAck
  CleanUpEUTEnvironmentBegin
  CleanUpEUTEnvironmentEnd
  return
}
ParsePacket L_Packet -t IPv6 -IPv6_payload L_Tcp6Packet
set L_Flag    [lrange $L_Tcp6Packet 13 13]
set L_Flag    [expr {$L_Flag & 0x37}]
set L_Flag    [format "%#04x" $L_Flag]
set L_Seq     [lrange $L_Tcp6Packet 4 7]
set L_AckAck  [expr {[Hex2Dec $L_Seq] + 1}]
set L_Ack     [lrange $L_Tcp6Packet 8 11]
set L_SeqAck  [expr {[Hex2Dec $L_Ack]}] 

set L_FINACK  [expr {$FIN | $ACK}]
set L_FINACK  [format "%#04x" $L_Flag]
if {[string compare $L_Flag $L_FINACK] != 0} {
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid  \
                  "Tcp6.Close - No FIN sent."

  BS->CloseEvent {@R_Close_CompletionToken1.Event, &@R_Status}
  GetAck
  BS->CloseEvent {@R_Connect_CompletionToken.Event, &@R_Status}
  GetAck
  CleanUpEUTEnvironmentBegin
  CleanUpEUTEnvironmentEnd
  return
}
#
# Check Point: Check whether the close event is signaled or not
#
GetVar R_Close_CompletionToken1.Status
if { ${R_Close_CompletionToken1.Status} != $EFI_INCOMPATIBLE_VERSION} {
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                             \
                  "Close should NOT be success.                \
                  ReturnStatus - ${R_Transmit_CompletionToken1.Status},\
                  ExpectedStatus - $EFI_INCOMPATIBLE_VERSION"

  BS->CloseEvent {@R_Close_CompletionToken1.Event, &@R_Status}
  GetAck
  BS->CloseEvent {@R_Connect_CompletionToken.Event, &@R_Status}
  GetAck
  CleanUpEutEnvironmentBegin
  CleanUpEutEnvironmentEnd
  return
}
#
# Check Point: Call Tcp6.Close() to close a connection with the last close has 
#              not finished. 
#
BS->CreateEvent "$EVT_NOTIFY_SIGNAL, $EFI_TPL_CALLBACK, 1, &@R_Context,        \
                 &@R_Close_CompletionToken2.Event, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "BS.CreateEvent."                                              \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
SetVar R_Close_CloseToken2.CompletionToken @R_Close_CompletionToken2
SetVar R_Close_CloseToken2.AbortOnClose   FALSE

Tcp6->Close {&@R_Close_CloseToken2, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_ACCESS_DENIED]
RecordAssertion $assert $Tcp6CloseConf5AssertionGuid001                     \
                "Tcp6.Close with last close has not finished."                      \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_ACCESS_DENIED"

#
# OS send back FIN|ACK to end the TCP session
#
set L_FlagAck  [expr {$FIN | $ACK}]
CreatePacket P_Tcp6PacketAck -t tcp -tcp_sp $L_PortSrc -tcp_dp $L_PortDst -tcp_control $L_FlagAck -tcp_seq $L_SeqAck -IP_ver 0x06 -tcp_ack $L_AckAck
SendPacket P_Tcp6PacketAck -c 1

Stall 5

#
# Clean Up
#

#
# Close Event for Connection
#
BS->CloseEvent {@R_Connect_CompletionToken.Event, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "BS.DestroyEvent. "                         \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
#
# Close Event for Close
#
BS->CloseEvent {@R_Close_CompletionToken1.Event, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "BS.DestroyEvent. "                         \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
BS->CloseEvent {@R_Close_CompletionToken2.Event, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "BS.DestroyEvent. "                         \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
CleanUpEUTEnvironmentBegin
CleanUpEUTEnvironmentEnd