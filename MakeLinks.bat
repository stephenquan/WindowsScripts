@ECHO OFF

SETLOCAL

SET AppSrc=C:\Applications\Melbourne\appstudio-framework
SET AppOutput=C:\Applications\output\winangle_x64_release\bin
SET AppStudio=%USERPROFILE%\Applications\ArcGIS\AppStudio
SET QtDir=C:\Qt\Qt5.8.0_64\5.8\msvc2015_64

CALL :MakeFrameworkLinks% Barcodes
CALL :MakeFrameworkLinks% VideoFilters
CALL :MakeRuntimeLinks

GOTO :EOF

:MakeFrameworkLinks
Set Plugin=%1
Set Dll=AppFramework%Plugin%Plugin.dll
Set QmlTypes=AppFramework%Plugin%Plugin.qmltypes
Call :MakeFrameworkLinks2 %AppStudio%\bin\qml\ArcGIS\AppFramework\%Plugin%
Call :MakeFrameworkLinks2 %AppStudio%\QtCreator\bin\qml\ArcGIS\AppFramework\%Plugin%
Call :MakeFrameworkLinks2 %AppStudio%\sdk\windows\x64\qml\ArcGIS\AppFramework\%Plugin%
Call :MakeFrameworkLinks2 %QtDir%\qml\ArcGIS\AppFramework\%Plugin%
GOTO :EOF

:MakeFrameworkLinks2
Set "Dst=%1"
MKDIR %Dst%
CALL :MakeLink %AppOutput%\%Dll% %Dst%\%Dll%
CALL :MakeLink %AppOutput%\%QmlTypes% %Dst%\%QmlTypes%
CALL :MakeLink %AppSrc%\AppFramework%Plugin%Plugin\qmldir %Dst%\qmldir
GOTO :EOF

:MakeRuntimeLinks
Set Plugin=ArcGISRuntime
Set Dll=%Plugin%Plugin.dll
Set QmlTypes=%Plugin%Plugin.qmltypes
Set Dst=%AppStudio%\bin\qml\ArcGIS\AppFramework\%Plugin%
CALL :MakeLink %AppOutput%\%Dll% %Dst%\%Dll%
CALL :MakeLink %AppOutput%\%QmlTypes% %Dst%\%QmlTypes%
Set Dst=%AppStudio%\QtCreator\bin\qml\ArcGIS\AppFramework\%Plugin%
CALL :MakeLink %AppOutput%\%Dll% %Dst%\%Dll%
CALL :MakeLink %AppOutput%\%QmlTypes% %Dst%\%QmlTypes%
Set Dst=%AppStudio%\sdk\windows\x64\qml\ArcGIS\AppFramework\%Plugin%
CALL :MakeLink %AppOutput%\%Dll% %Dst%\%Dll%
CALL :MakeLink %AppOutput%\%QmlTypes% %Dst%\%QmlTypes%
Set Dst=%QtDir%\qml\ArcGIS\AppFramework\%Plugin%
CALL :MakeLink %AppOutput%\%Dll% %Dst%\%Dll%
CALL :MakeLink %AppOutput%\%QmlTypes% %Dst%\%QmlTypes%
GOTO :EOF

:MakeLink
SET "TARGET=%1"
SET "LINK=%2"
IF EXIST "%LINK%" DEL "%LINK%"
MKLINK "%LINK%" "%TARGET%"
GOTO :EOF
