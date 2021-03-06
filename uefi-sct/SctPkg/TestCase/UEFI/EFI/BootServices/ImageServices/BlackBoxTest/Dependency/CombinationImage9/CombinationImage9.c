/** @file

  Copyright 2006 - 2017 Unified EFI, Inc.<BR>
  Copyright (c) 2010 - 2017, Intel Corporation. All rights reserved.<BR>

  This program and the accompanying materials
  are licensed and made available under the terms and conditions of the BSD License
  which accompanies this distribution.  The full text of the license may be found at 
  http://opensource.org/licenses/bsd-license.php
 
  THE PROGRAM IS DISTRIBUTED UNDER THE BSD LICENSE ON AN "AS IS" BASIS,
  WITHOUT WARRANTIES OR REPRESENTATIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED.
 
**/
/*++

Module Name:

  CombinationImage9.c

Abstract:

  for Image Boot Services Black Box Test

--*/

#include "ProtocolDefinition.h"
#include "Misc.h"
#include <Library/EfiTestLib.h>

//
// data definition here
//

EFI_STATUS
EFIAPI
InitializeCombinationImage9 (
  IN EFI_HANDLE           ImageHandle,
  IN EFI_SYSTEM_TABLE     *SystemTable
  );


EFI_STATUS
EFIAPI
InitializeCombinationImage9 (
  IN EFI_HANDLE           ImageHandle,
  IN EFI_SYSTEM_TABLE     *SystemTable
  )
{
  EFI_STATUS                  Status;
  EFI_HANDLE                  Handle;
  EFI_DEVICE_PATH_PROTOCOL    *FilePath;
  EFI_HANDLE                  AnotherImageHandle;
  CHAR16                      *ExitData;
  UINTN                       ExitDataSize;

  //
  // Init
  //
  FilePath = NULL;
  Handle = NULL;
  AnotherImageHandle = NULL;
  Status = EFI_SUCCESS;
  ExitData = NULL;

  EfiInitializeTestLib (ImageHandle, SystemTable);

  SctInitializeLib (ImageHandle, SystemTable);

  gtBS->InstallProtocolInterface (
          &Handle,
          &mImageTestNoInterfaceProtocol9Guid,
          EFI_NATIVE_INTERFACE,
          NULL
          );

  Status = ImageTestComposeSimpleFilePath (
             NULL,ImageHandle,
             COMBINATION_IMAGE_10_NAME,
             &FilePath
             );
  if (EFI_ERROR(Status)) {
    goto Done;
  }

  //
  // load image 10
  //
  Status = gtBS->LoadImage (
                   FALSE,
                   ImageHandle,
                   FilePath,
                   NULL,
                   0,
                   &AnotherImageHandle
                   );
  if (EFI_ERROR(Status)) {
    goto Done;
  }

  //
  // start image 10
  //
  Status = gtBS->StartImage (AnotherImageHandle, &ExitDataSize, &ExitData);

Done:

  if (Handle != NULL) {
    gtBS->UninstallProtocolInterface (
            Handle,
            &mImageTestNoInterfaceProtocol9Guid,
            NULL
            );
  }

  if (ExitData != NULL) {
    gtBS->FreePool (ExitData);
  }

  if (FilePath != NULL) {
    gtBS->FreePool (FilePath);
  }

  if (AnotherImageHandle != NULL) {
    gtBS->UnloadImage (AnotherImageHandle);
  }

  gtBS->Exit (ImageHandle, Status, 0, NULL);

  //
  // actually should not arrive here. Just to pass compiling.
  //
  return EFI_SUCCESS;
}
