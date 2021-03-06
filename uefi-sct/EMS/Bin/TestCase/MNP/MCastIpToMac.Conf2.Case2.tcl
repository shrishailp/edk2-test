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
set reportfile    report.csv

#
# test case Name, category, description, GUID...
#
CaseGuid        BA46645C-E72F-415b-8FC1-F6CBB434FA73
CaseName        MCastIpToMac.Conf2.Case2
CaseCategory    MNP
CaseDescription {Test Conformance of MCastIPToMac of MNP - Call McastlpToMac() \
	               with the parameter *IpAddress being invalid multicast IP      \
	               address. The return status should be EFI_INVALID_PARAMETER.}
################################################################################

Include MNP/include/Mnp.inc.tcl

#
# Begin log ...
#
BeginLog
BeginScope  _MNP_MCASTIPTOMAC_CONFORMANCE2_CASE2_

#
# Parameter Definition
# R_ represents "Remote EFI Side Parameter"
# L_ represents "Local OS Side Parameter"
#
UINTN                             R_Status
UINTN                             R_Handle
EFI_MANAGED_NETWORK_CONFIG_DATA   R_MnpConfData               
EFI_IP_ADDRESS                    R_IpAddr
EFI_MAC_ADDRESS                   R_MacAddr
#
# Create child R_Handle
#
MnpServiceBinding->CreateChild {&@R_Handle, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Mnp.MCaseIpToMac - Conf1 - create child"                      \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"	
SetVar     [subst $ENTS_CUR_CHILD]  @R_Handle

#
# Configure this child 
#
SetMnpConfigData R_MnpConfData 0 0 0 TRUE FALSE TRUE TRUE FALSE FALSE TRUE
Mnp->Configure {&@R_MnpConfData, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Mnp.MCaseIpToMac - Invalid parameter - Configure"             \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

SetIpv4Address      R_IpAddr.v4  "234.1.1.1"
#
# Call MCastIpToMac with invalid parameters
# B). *IpAddress is not a valid multicast IP address, 192.168.1.1
#
SetIpv4Address      R_IpAddr.v4  "192.168.1.1"
Mnp->MCastIpToMac   "FALSE, &@R_IpAddr, &@R_MacAddr, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_INVALID_PARAMETER]
RecordAssertion $assert $MnpMCastIpToMacConf2AssertionGuid002                  \
                "Mnp.MCaseIpToMac - Invalid parameter - IPADDRESS NOT MULTICAST"\
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_INVALID_PARAMETER"

DestructVar R_IpAddr R_MacAddr

#
# Destroy child R_Handle
#
MnpServiceBinding->DestroyChild {@R_Handle, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Mnp.MCaseIpToMac - Conf1 - destroy child"                     \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

DestructVar R_Status R_Handle R_MnpConfData

EndScope    _MNP_MCASTIPTOMAC_CONFORMANCE2_CASE2_

#
# End log
#
EndLog
