#Region Variables

&AtClient
Перем UT_CurrentRequestsRowID; //Number

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	InitialHeader = Title;

	InitializeForm();


	If Parameters.Property("DebugData") Then
		//@skip-check unknown-form-parameter-access
		FillByDebaggingData(Parameters.DebugData);
	EndIf;

	UT_Common.ToolFormOnCreateAtServer(ThisObject,
										Cancel,
										StandardProcessing,
										CommandBar);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	UpdateTitle();
	SetRequestHeaderEditingPage();

	If ValueIsFilled(RequestsFileName) Then
		LoadFileConsole(True);
	EndIf;
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	If Parameters.Property("DebugData") Then
		RequestsFileName = "";
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region RequestHeaders

&AtClient
Procedure EditHeadersWithTableOnChange(Item)
	SetRequestHeaderEditingPage();
EndProcedure

#EndRegion


&AtClient
Procedure RequestBodyEncodingOnChange(Item)
	SetHeadersByRequestBodyContents();
EndProcedure

&AtClient
Procedure RequestsTreeTypeOfStringContentOnChange(Item)
	SetHeadersByRequestBodyContents();
EndProcedure

&AtClient
Procedure RequestBodyTypeOnChange(Item)
	OnChangeRequestBodyType();

EndProcedure

&AtClient
Procedure BodyFileNameStartChoice(Item, ChoseData, StandardProcessing)
	RequestString = CurrentRequestRow();	
	Если RequestString = Undefined Then
		Return;
	EndIf;
	
	FileDialog = New FileDialog(FileDialogMode.Open);
	FileDialog.Multiselect = False;
	FileDialog.FullFileName = RequestString.BodyFileName;

	CallBackParameters = New Structure;
	CallBackParameters.Insert("RowID", RequestString.GetID());

	FileDialog.Show(New CallbackDescription("RequestBodyFileNameStartChooseFinish", ThisObject, CallBackParameters));
EndProcedure


&AtClient
Procedure RequestURLOnChange(Item)
	SetPreliminaryURL(UT_CurrentRequestsRowID);
EndProcedure

&AtClient
Procedure HeadersStringOnChange(Item)
	//FillJSONStructureInRequestsTree();
EndProcedure


&AtClient
Procedure RequestsTreeAuthenticationTypeOnChange(Item)
	OnChangeRequestAuthenticationType();
EndProcedure


#EndRegion

#Region FormTableItemsEventHandlers_RequestsTree

&AtClient
Procedure RequestsTreeOnActivateRow(Item)
	AttachIdleHandler("RequestsTreeRowWaitHandlerActivation", 0.1, True);
EndProcedure


&AtClient
Procedure RequestsTreeOnStartEdit(Item, NewRow, Copy)
	If Not NewRow Then
		Return;
	EndIf;
	If Copy Then
		Return;
	EndIf;
	
	CurrentData = Items.RequestsTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	InitializeRequestsTreeString(CurrentData, ThisObject);
EndProcedure

&AtClient
Procedure RequestsTreeBeforeEditEnd(Item, NewRow, EditCancel, Cancel)
	If EditCancel Then
		Return;
	EndIf;	
	
	CurrentData = Items.RequestsTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(CurrentData.Name) Then
		Cancel = True;
	EndIf;

EndProcedure


#EndRegion

#Region FormTableItemsEventHandlers_RequestHeadersTable


&AtClient
Procedure RequestHeadersTableOnStartEdit(Item, NewRow, Clone)
	If Not NewRow Then
		Return;
	EndIf;
	Если Clone Then
		Return;
	EndIf;
	
	CurrentData = Items.RequestHeadersTable.CurrentData;
	Если CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData.Using = True;
EndProcedure

&AtClient
Procedure RequestHeadersTableOnChange(Item)
	//FillJSONStructureInRequestsTree();
EndProcedure

&AtClient
Procedure TableRequestHeadersTableKeyAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, 
	StandardProcessing)

	StandardProcessing = False;

	If Not ValueIsFilled(Text) Then
		Return;
	EndIf;

	ChoseData = New ValueList;

	For Each ListItem In ListOfUsedHeaders Do
		If СтрНайти(Lower(ListItem.Value), Lower(Text)) > 0 Then
			ChoseData.Add(ListItem.Value);
		EndIf;
	EndDo;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers_RequestsTreeMultipartBody
&AtClient
Procedure MultipartBodyRequestsTreeOnStartEdit(Item, NewRow, Copy)
	If Not NewRow Then
		Return;
	EndIf;
	If Copy Then
		Return;
	EndIf;
	
	CurrentData = Items.MultipartBodyRequestsTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	CurrentData.Using = True;
	CurrentData.Type = MultypartItemsType().File;
EndProcedure

&AtClient
Procedure MultipartBodyRequestsTreeValueStartChoice(Item, ChoiceData, StandardProcessing)
	CurrentData = Items.MultipartBodyRequestsTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Types = MultypartItemsType();
	
	CallBackParameters = New Structure;
	CallBackParameters.Insert("RowRequestIdentifier", UT_CurrentRequestsRowID);
	CallBackParameters.Insert("BodyRowIdentifier", CurrentData.GetID());

	CallbackDescriptionAboutFinish = New CallbackDescription("TreeRequestsBodyMultipartValueStartChoseFinishChose",
		ThisObject, CallBackParameters);

	Если CurrentData.Type = Types.File Then
		FileDialog = New FileDialog(FileDialogMode.Open);
		FileDialog.CheckFileExistence = True;
		FileDialog.Multiselect = False;
		FileDialog.Show(New CallbackDescription("FileTreeRequestsBodyMultipartValueStartChoseFinishChose",
			ThisObject, New Structure("CallbackDescriptionAboutFinish", CallbackDescriptionAboutFinish)));
	Else
		UT_CommonClient.OpenTextEditingForm(CurrentData.Value, CallbackDescriptionAboutFinish);
	EndIf;
EndProcedure



#EndRegion

#Region FormTableItemsEventHandlers_URLParameters

&AtClient
Procedure URLParametersOnStartEdit(Item, NewRow, Copy)

	If Not NewRow Then
		Return;
	EndIf;

	If Copy Then
		Return;
	EndIf;
	CurrentData = Items.URLParameters.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData.Using = True;
EndProcedure

&AtClient
Procedure URLParametersOnChange(Item)
	SetPreliminaryURL(UT_CurrentRequestsRowID);
EndProcedure


#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RequestTreeMoveToLevelUp(Command)
	
	Row = RequestsTree.FindByID(Items.RequestsTree.CurrentRow);
	Parent = Row.GetParent();

	Если Parent <> Undefined Then
		ParentsParent = Parent.GetParent();
		Если ParentsParent = Undefined Then
			InsertIndex = RequestsTree.GetItems().Index(Parent) + 1;
		Else
			InsertIndex = ParentsParent.GetItems().Index(Parent) + 1;
		EndIf;
		
		NewRow = MoveTreeRow(RequestsTree, Row, InsertIndex, ParentsParent);
		
		Items.RequestsTree.CurrentRow = NewRow.GetID();
	EndIf;

	Modified = True;
	
EndProcedure

&AtClient
Procedure RequestExecute(Command)
	SaveRequestDataInRequestsTree();
	
	RequestString  = CurrentRequestRow();
	If RequestString = Undefined Then
		Return;
	EndIf;
	
	If Not PossibleRequestExecution(RequestString) Then
		Return;	
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("RequestString", RequestString);
	If SaveBeforeExecution And ValueIsFilled(RequestsFileName) Then
		ExecuteSavingRequestsToFile( , New CallbackDescription("ExecuteRequestFinishFileSaving",
			ThisObject, AdditionalParameters));
	Else
		ExecuteRequestFinishFileSaving(True, AdditionalParameters);
	EndIf;
EndProcedure

&AtClient
Procedure FillBodyBinaryDataFromFile(Command)
	If UT_CurrentRequestsRowID = Undefined Then
		Return;
	EndIf;
	
	CallBackParameters = New Structure();
	CallBackParameters.Insert("CurrentRowID", UT_CurrentRequestsRowID);
	
	BeginPutFile(New CallbackDescription("FillBodyBinaryDataFromFileFinish", ThisObject,
		CallBackParameters), , "", True, UUID);
EndProcedure

&AtClient
Procedure SaveBodyRequestBinaryDataFromHistory(Command)
	CurrentDataRequestHistory = Items.RequestsHistory.CurrentData;
	If CurrentDataRequestHistory = Undefined Then
		Return;
	EndIf;

	If Not IsTempStorageURL(CurrentDataRequestHistory.RequestBodyBinaryDataAddress) Then
		Return;
	EndIf;

	FileDialog = New FileDialog(FileDialogMode.Save);
	FileDialog.Multiselect = False;

	SaveParameters = UT_CommonClient.NewFileSavingParameters();
	SaveParameters.FileDialog = FileDialog;
	SaveParameters.TempStorageFileDirectory = CurrentDataRequestHistory.RequestBodyBinaryDataAddress;
	UT_CommonClient.BeginFileSaving(SaveParameters);

EndProcedure

&AtClient
Procedure SaveBinaryDataBodyAnswerInFile(Command)
	CurrentDataRequestHistory = Items.RequestsHistory.CurrentData;
	If CurrentDataRequestHistory = Undefined Then
		Return;
	EndIf;

	If Not IsTempStorageURL(CurrentDataRequestHistory.ResponseBodyBinaryDataAddress) Then
		Return;
	EndIf;

	FileDialog = New FileDialog(FileDialogMode.Save);
	FileDialog.Multiselect = False;

	SaveParameters = UT_CommonClient.NewFileSavingParameters();
	SaveParameters.FileDialog = FileDialog;
	SaveParameters.TempStorageFileDirectory = CurrentDataRequestHistory.ResponseBodyBinaryDataAddress;
	UT_CommonClient.BeginFileSaving(SaveParameters);

EndProcedure

&AtClient
Procedure RecordHistoryRequestDetailedInformation(Command)
	RequestString = CurrentRequestRow();
	If RequestString = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Items.RequestsTreeRequestsHistory.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("RequestRow", RequestString.GetID());
	FormParameters.Insert("HistoryRow", CurrentData.GetID());

	OpenForm("DataProcessor.UT_HTTPRequestConsole.Form.FormRequestDetails",
				 FormParameters,
				 ThisObject,
				 ""
				 + UUID
				 + RequestString.GetID()
				 + CurrentData.GetID());
EndProcedure


&AtClient
Procedure SaveBodyResponseBinaryData(Command)
	If Not IsTempStorageURL(ResponseBodyBinaryDataAddress) Then
		Return;
	EndIf;

	FileDialog = New FileDialog(FileDialogMode.Save);
	FileDialog.Multiselect = False;

	SaveParameters = UT_CommonClient.NewFileSavingParameters();
	SaveParameters.FileDialog = FileDialog;
	SaveParameters.TempStorageFileDirectory = ResponseBodyBinaryDataAddress;
	UT_CommonClient.BeginFileSaving(SaveParameters);
EndProcedure

&AtClient
Procedure NewRequestFile(Command)
	If RequestsTree.GetItems().Count() = 0 Then
		InitializeConsole();
	Else
		ShowQueryBox(New CallbackDescription("NewRequestFileFinish", ThisObject),
			NStr("ru = 'Дерево запросов непустое. Продолжить?'; en = 'The query tree is not empty. Continue?'"), QuestionDialogMode.YesNo, 15, DialogReturnCode.No);
	EndIf;
EndProcedure

&AtClient
Procedure OpenRequestFile(Command)
	If RequestsTree.GetItems().Count() = 0 Then
		LoadFileConsole();
	Else
		ShowQueryBox(New CallbackDescription("OpenReportFileFinish", ThisObject),
			NStr("ru = 'Дерево запросов непустое. Продолжить?'; en = 'The query tree is not empty. Continue?'"), QuestionDialogMode.YesNo, 15, DialogReturnCode.No);
	EndIf;
EndProcedure

&AtClient
Procedure SaveRequestsToFile(Command)
	ExecuteSavingRequestsToFile();
EndProcedure

&AtClient
Procedure SaveRequestsToFileAs(Command)
	ExecuteSavingRequestsToFile(True);
EndProcedure

&AtClient
Procedure EditRequestBodyInJSONEditor(Command)
	TreeRow = CurrentRequestRow();
	Если TreeRow = Undefined Then
		Return;
	EndIf;
	
	CallBackParameters = New Structure;
	CallBackParameters.Insert("CurrentRow", TreeRow.GetID());

	UT_CommonClient.EditJSON(TreeRow.BodyString,
		False,
		New CallbackDescription("EditRequestBodyInJSONEditorFinish",
		ThisObject, CallBackParameters));
EndProcedure

&AtClient
Procedure EditRequestBodyInJSONEditorAnalyzedRequest(Command)
	UT_CommonClient.EditJSON(Items.RequestsHistory.CurrentData.RequestBodyString, True);
EndProcedure

&AtClient
Procedure EditResponseBodyInJSONEditorAnalyzedRequest(Command)
	UT_CommonClient.EditJSON(ResponseBodyString, True);
EndProcedure

&AtClient
Procedure CopyRowDataHistoryToRequest(Command)
	RequestString = CurrentRequestRow();
	If RequestString = Undefined Then
		Return;
	EndIf;
	
	HistoryRow = Items.RequestsTreeRequestsHistory.CurrentData;
	If RequestString = Undefined Then
		Return;
	EndIf;
	CopyDataRowHistoryToRequestAtServer(RequestString.GetID(),
										HistoryRow.GetID());
	ExtractRequestDataFromTreeRow();
EndProcedure

&AtClient
Procedure GenerateExecutionCode(Command)
	CurrentData = Items.RequestsTree.CurrentData;
	Если CurrentData = Undefined Then
		Return;
	EndIf;
	SaveRequestDataInRequestsTree();

	GeneratedCode = GeneratedExecutionCodeAtServer(CurrentData.GetID());

	UT_CommonClient.OpenCodeStringCodeSpecialForm(GeneratedCode, "HTTP request: " + CurrentData.Name, ""
												+ UUID
												+ CurrentData.GetID());
EndProcedure

//@skip-warning
&AtClient
Procedure Attachable_ExecuteToolsCommonCommand(Command) 
	UT_CommonClient.Attachable_ExecuteToolsCommonCommand(ThisObject, Command);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ExecuteRequestFinishFileSaving(Result, AdditionalParameters) Export
	If Result <> True Then
		Return;
	EndIf;
	RequestString = AdditionalParameters.RequestString;
	
	NextStepParameters = New Structure;
	NextStepParameters.Insert("RowID", RequestString.GetID());
	NextStepParameters.Insert("File", Undefined);
	NextStepParameters.Insert("AtClient", RequestString.AtClient);
	
	If RequestString.BodyType = TypesOfRequestBody.File Then
		If RequestString.AtClient Then
			NextStepParameters.File = New Structure;
			NextStepParameters.File.Insert("FullName", RequestString.BodyFileName);
			ExecuteRequestPreparatoryActionsFinish(NextStepParameters);
		Else
			ReadingParametersФайла = UT_CommonClient.NewFileReadingParameters(UUID);
			ReadingParametersФайла.FullFileName = RequestString.BodyFileName;
			ReadingParametersФайла.EndingCallbackDescription = New CallbackDescription("ExecuteRequestReadingFilesMultiFinishInTemporaryStorage",
				ThisObject, NextStepParameters);

			UT_CommonClient.BeginFileReading(ReadingParametersФайла);
		EndIf;
	ElsIf RequestString.BodyType = TypesOfRequestBody.MultypartForm Then
		GetStartedPuttingFilesInTemporaryStorageForBodyRowsMultipart(RequestString,
			New CallbackDescription("ExecuteRequestReadingFilesMultiPartFinishInTemporaryStorage",
			ThisObject, NextStepParameters));
	Else
		ExecuteRequestPreparatoryActionsFinish(NextStepParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure GetStartedPuttingFilesInTemporaryStorageForBodyRowsMultipart(RequestString, CallbackDescriptionAboutFinish)
	FormDataTreeItem = New Structure;
	FormDataTreeItem.Insert("CallbackDescriptionAboutFinish", CallbackDescriptionAboutFinish);
	FormDataTreeItem.Insert("RequestsTreeRow", RequestString);
	FormDataTreeItem.Insert("RowsMultipartIndex", 0);
	FormDataTreeItem.Insert("PlacedFilesMap", New Map);

	UT_CommonClient.AttachFileSystemExtensionWithPossibleInstallation(New CallbackDescription("GetStartedPuttingFilesInTemporaryStorageForBodyRowsMultipartCompletingConnectionsExtensionsWorkingWithFiles",
		ThisObject, FormDataTreeItem));
EndProcedure


// Начать помещение файлов во временное хранилище для строк тела мультипарт завершение подключения расширения работы с файлам.
// 
// Parameters:
//  Connected - Boolean- Connected
//  AdditionalParameters - Structure:
//  * CallbackDescriptionAboutFinish - CallbackDescription
//  * RequestsTreeRow - FormDataTreeItem
&AtClient
Procedure GetStartedPuttingFilesInTemporaryStorageForBodyRowsMultipartCompletingConnectionsExtensionsWorkingWithFiles(Connected,
	AdditionalParameters) Export
	If Not Connected Then
		Return;
	EndIf;
	
	PlaceNextFileMultipart(AdditionalParameters);
EndProcedure

// Place another multipart file.
// 
// Parameters:
//  AdditionalParameters - Structure:
//  * CallbackDescriptionAboutFinish - CallbackDescription
//  * RequestsTreeRow - FormDataTreeItem
//  * PlacedFilesMap - Map из KeyAndValue
//  * RowsMultipartIndex - Number
&AtClient
Procedure PlaceNextFileMultipart(AdditionalParameters)
	MultipartTypes = MultypartItemsType();
	
	For Index = AdditionalParameters.RowsMultipartIndex To AdditionalParameters.RequestsTreeRow.MultipartBody.Count()
																	  - 1 Do
		MultypartItemRow = AdditionalParameters.RequestsTreeRow.MultipartBody[Index];
		If MultypartItemRow.Type <> MultipartTypes.File Then
			Continue;
		EndIf;
		If Not ValueIsFilled(MultypartItemRow.Value) Then
			Continue;
		EndIf;

		AdditionalParameters.RowsMultipartIndex = Index;

		ReadingParameters = UT_CommonClient.NewFileReadingParameters(UUID);
		ReadingParameters.FileSystemExtensionAttached = True;
		ReadingParameters.FullFileName = MultypartItemRow.Value;
		ReadingParameters.EndingCallbackDescription = New CallbackDescription("PlaceNextFileMultipartCompletingReadingNextFile",
			ThisObject, AdditionalParameters);

		UT_CommonClient.BeginFileReading(ReadingParameters);
		Return;
	EndDo;

	RunCallback(AdditionalParameters.CallbackDescriptionAboutFinish,
								 AdditionalParameters.PlacedFilesMap);
EndProcedure

// Place the next file multipart completion of reading the next file.
// 
// Parameters:
//  Result - Массив In Structure:
//  	* FullName - String
//  	* Storage - String
//  AdditionalParameters - Structure:
//  	* CallbackDescriptionAboutFinish - CallbackDescription
//  	* RequestsTreeRow - FormDataTreeItem
//  	* PlacedFilesMap - Map of KeyAndValue
//  	* RowsMultipartIndex - Number
&AtClient
Procedure PlaceNextFileMultipartCompletingReadingNextFile(Result, AdditionalParameters) Export
	If Result <> Undefined Then
		If Result.Count() > 0 Then
			AdditionalParameters.PlacedFilesMap.Insert(AdditionalParameters.RowsMultipartIndex,
																		  Result[0].Storage);
		EndIf;
	EndIf;
	AdditionalParameters.RowsMultipartIndex = AdditionalParameters.RowsMultipartIndex + 1;
	PlaceNextFileMultipart(AdditionalParameters);
EndProcedure


&AtClient
Procedure FileTreeRequestsBodyMultipartValueStartChoseFinishChose(ChosenFiles, AdditionalParameters) Export
	If ChosenFiles = Undefined Then
		Return;
	EndIf;
	If ChosenFiles.Count() = 0  Then
		Return;
	EndIf;
	
	RunCallback(AdditionalParameters.CallbackDescriptionAboutFinish, ChosenFiles[0]);
EndProcedure

// Request tree body multipart value start of selection completion of selection..
// 
// Parameters:
//  Result - Строка, Undefined - Result
//  AdditionalParameters - Structure:
//  * RowRequestIdentifier - Number
//  * BodyRowIdentifier - Number
&AtClient
Procedure TreeRequestsBodyMultipartValueStartChoseFinishChose(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	TreeRow = RequestsTree.FindByID(AdditionalParameters.RowRequestIdentifier);
	If TreeRow = Undefined Then
		Return;
	EndIf;
	
	BodyRow = TreeRow.MultipartBody.FindByID(AdditionalParameters.BodyRowIdentifier);
	If BodyRow = Undefined Then
		Return;
	EndIf;
	
	BodyRow.Value = Result;
	Modified = True;
EndProcedure

&AtClient
Procedure RequestsTreeRowWaitHandlerActivation()
	SaveRequestDataInRequestsTree();
	
	CurrentData = Items.RequestsTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	UT_CurrentRequestsRowID = CurrentData.GetID();
	ExtractRequestDataFromTreeRow();
	
EndProcedure

&AtClient
Procedure SetHeadersByRequestBodyContents()
	TreeRow = CurrentRequestRow();
	If TreeRow = Undefined Then
		Return;
	EndIf;
	
	ContentsHeaderValue = "";

	If TreeRow.BodyType = TypesOfRequestBody.String Then
		If TreeRow.TypeOfStringContent <> "None" And ValueIsFilled(TreeRow.TypeOfStringContent) Then
			TextTypes = TextContentTypes();
			If TextTypes.Property(TreeRow.TypeOfStringContent) Then
				ContentsHeaderValue = TextTypes[TreeRow.TypeOfStringContent];

				Encoding = "";
				
				Encodings = RequestBodyEncodingsTypes();
								
				If TreeRow.BodyEncoding = Encodings.Auto
					Or TreeRow.BodyEncoding = Encodings.System Then
						
				ElsIf TreeRow.BodyEncoding = Encodings.UTF8 Then 
					Encoding="utf-8";
				ElsIf TreeRow.BodyEncoding = Encodings.ANSI Then 
					Encoding = "windows-1251";
				ElsIf TreeRow.BodyEncoding = Encodings.UTF16 Then 
					Encoding = "utf-16";
				ElsIf TreeRow.BodyEncoding = Encodings.OEM Then 
					Encoding = "cp866";
				ElsIf ValueIsFilled(TreeRow.BodyEncoding) Then
					Encoding = TreeRow.BodyEncoding;
				EndIf;
				If ValueIsFilled(Encoding) Then
					ContentsHeaderValue = ContentsHeaderValue
												   + "; charset="
												   + Encoding;
				EndIf;
			EndIf;
		EndIf;
	ElsIf TreeRow.BodyType = TypesOfRequestBody.BinaryData Then 
		//ContentsHeaderValue = "application/octet-stream";	
	ElsIf TreeRow.BodyType = TypesOfRequestBody.MultypartForm Then
		ContentsHeaderValue = "multipart/form-data; boundary=" + MultipartBodySplitter;
	Else
		Return;
	EndIf;
		
	SearchHeaderName = "Content-Type";
	
	If ValueIsFilled(ContentsHeaderValue) Then
		AddRequestHeader(SearchHeaderName, ContentsHeaderValue);
//	Else
//		RemoveRequestHeader(SearchHeaderName);
	EndIf;

EndProcedure

&AtClient
Procedure AddRequestHeader(HeaderName, HeaderValue)
	If EditHeadersWithTable Then
		FoundHeaderString = False;
		For Each Str In RequestHeadersTable Do
			If Lower(HeaderName) = Lower(Str.Key) Then
				Str.Using = True;
				Str.Value = HeaderValue;
				
				FoundHeaderString = True;
				Break;
			EndIf;
		EndDo;
		
		If Not FoundHeaderString Then
			Str = RequestHeadersTable.Add();
			Str.Using = True;
			Str.Key = HeaderName;
			Str.Value = HeaderValue;	
		EndIf;
	Else
		HeadersRows = StrSplit(HeadersString, Chars.LF);
		
		SearchedHeadIndex = Undefined;
		
		For Index = 0 To HeadersRows.Count() -1 Do
			Str = HeadersRows[Index];
			
			If Not ValueIsFilled(Str) Then
				Continue;
			EndIf;
			
			HeaderArray = StrSplit(Str, ":");
			If Lower(HeaderArray[0]) = Lower(HeaderName) Then
				SearchedHeadIndex = Index;
				Break;
			EndIf;
		EndDo;
		
		InsertsString = StrTemplate("%1:%2", HeaderName, HeaderValue);
		
		If SearchedHeadIndex = Undefined Then
			HeadersRows.Add(InsertsString);
		Else
			HeadersRows[SearchedHeadIndex] = InsertsString;
		EndIf;
			
		HeadersString = StrConcat(HeadersRows, Chars.LF);
		
	EndIf;
EndProcedure

&AtClient 
Procedure RemoveRequestHeader(HeaderName)
	If EditHeadersWithTable Then
		DeletedRow = Undefined;
		For Each Str In RequestHeadersTable Do
			If Lower(HeaderName) = Lower(Str.Key) Then
				DeletedRow = Str;
				Break;
			EndIf;
		EndDo;
		
		If DeletedRow <> Undefined Then
			RequestHeadersTable.Delete(DeletedRow);
		EndIf;
	Else
		HeadersRows = StrSplit(HeadersString, Chars.LF);
		
		SearchedHeadIndex = Undefined;
		
		For Index = 0 To HeadersRows.Count() - 1 Do
			Str = HeadersRows[Index];
			
			If Not ValueIsFilled(Str) Then
				Continue;
			EndIf;
			
			HeaderArray = StrSplit(Str, ":");
			Если Lower(HeaderArray[0]) = Lower(HeaderName) Then
				SearchedHeadIndex = Index;
				Break;
			EndIf;
		EndDo;

		If SearchedHeadIndex <> Undefined Then
			HeadersRows.Delete(SearchedHeadIndex);
			HeadersString = StrConcat(HeadersRows, Chars.LF);
		EndIf;
		
	EndIf;	
EndProcedure

&AtClient
Function MoveTreeRow(Tree, MovableRow, InsertIndex, NewParent, Level = 0)

	If Level = 0 Then

		If NewParent = Undefined Then
			NewRow = Tree.GetItems().Insert(InsertIndex);
		Else
			NewRow = NewParent.GetItems().Insert(InsertIndex);
		EndIf;

		FillPropertyValues(NewRow, MovableRow);
		MoveTreeRow(Tree, MovableRow, InsertIndex, NewRow, Level + 1);

		MovableRowParent = MovableRow.GetParent();
		If MovableRowParent = Undefined Then
			Tree.GetItems().Delete(MovableRow);
		Else
			MovableRowParent.GetItems().Delete(MovableRow);
		EndIf;

	Else

		For Each Row In MovableRow.GetItems() Do
			NewRow = NewParent.GetItems().Add();
			
			FillPropertyValues(NewRow, MovableRow);
			
			MoveTreeRow(Tree, Row, NewRow, InsertIndex, Level + 1);
		EndDo;

	EndIf;

	Return NewRow;

EndFunction




&AtServer
Procedure CopyDataRowHistoryToRequestAtServer(RowRequestIdentifier, RowHistoryIdentifier)
	RequestString = RequestsTree.FindByID(RowRequestIdentifier);
	HistoryRow = RequestString.RequestsHistory.FindByID(RowHistoryIdentifier);
	
	RequestString.RequestURL = HistoryRow.RequestURL;
	RequestString.BodyType = HistoryRow.RequestBodyType;
	RequestString.HTTPRequest = HistoryRow.HTTPFunction;
	RequestString.BodyFileName = HistoryRow.RequestBodyFileName;
	RequestString.UseBOM = HistoryRow.BOM;
	RequestString.UseProxy = HistoryRow.UseProxy;
	RequestString.BodyEncoding = HistoryRow.RequestBodyEncoding;
	RequestString.ProxyOSAuthentication = HistoryRow.ProxyOSAuthentication;
	RequestString.ProxyPassword = HistoryRow.ProxyPassword;
	RequestString.ProxyPort = HistoryRow.ProxyPort;
	RequestString.ProxyUser = HistoryRow.ProxyUser;
	RequestString.ProxyServer = HistoryRow.ProxyServer;
	RequestString.Timeout = HistoryRow.Timeout;
	RequestString.BodyString = HistoryRow.RequestBodyString;

	RequestString.BodyBinaryData = Undefined;
	If IsTempStorageURL(HistoryRow.RequestBodyBinaryDataAddress) Then
		BinaryData = GetFromTempStorage(HistoryRow.RequestBodyBinaryDataAddress);
		If TypeOf(BinaryData) = Type("BinaryData") Then
			RequestString.BodyBinaryData = UT_Common.ValueStorageContainerBinaryData(BinaryData);
		EndIf;
	EndIf;
	
	FillHeadersTableByString(HistoryRow.RequestHeaders, RequestString.Headers);
//	RequestString.URLParameters = HistoryRow.RequestBodyEncoding;

EndProcedure

&AtClient
Function SavedFileDescriptionStructure()
	Structure = UT_CommonClient.EmptyDescriptionStructureOfSelectedFile();
	Structure.FileName = RequestsFileName;

	// For now, let's comment out saving in JSON, because... the library generates errors on binary data
	UT_CommonClient.AddFormatToSavingFileDescription(Structure,
		NStr("ru = 'Файл запросов консоли HTTP (*.uihttp)'; en = 'HTTP console request file (*.uihttp)'"), "uihttp");

	Return Structure;
EndFunction

&AtClient
Procedure ExecuteSavingRequestsToFile(SaveAs = False, CallbackDescriptionAboutFinish = Undefined)
	SaveRequestDataInRequestsTree();
	
	AdditionalCallbackParameters = Undefined;
	If CallbackDescriptionAboutFinish <> Undefined Then
		AdditionalCallbackParameters = New Structure;
		AdditionalCallbackParameters.Insert("CallbackDescriptionAboutFinish", CallbackDescriptionAboutFinish);
	EndIf;

	UT_CommonClient.SaveConsoleDataToFile("HTTPRequestConsole",
						SaveAs,
						SavedFileDescriptionStructure(),
						GetFileDataStringToSaveInFile(),
						New CallbackDescription("SaveToFileFinish",
		ThisObject, AdditionalCallbackParameters));

EndProcedure

&AtClient
Procedure OnChangeRequestBodyType()
	RequestString = CurrentRequestRow();	
	If RequestString = Undefined Then
		Return;
	EndIf;
		
	If RequestString.BodyType = TypesOfRequestBody.Bodyless Then
		NewPage = Items.RequestBodyBodylessPageGroup;
	ElsIf RequestString.BodyType = TypesOfRequestBody.String Then
		NewPage = Items.RequestBodyStringPageGroup;
	ElsIf RequestString.BodyType = TypesOfRequestBody.BinaryData Then
		NewPage = Items.BinaryDataRequestBodyPageGroup;
	ElsIf RequestString.BodyType = TypesOfRequestBody.MultypartForm Then 
		NewPage = Items.BodyMultypartPageGroup;
	Else
		NewPage = Items.BodyFileNameRequestBodyPageGroup;
	EndIf;

	Items.RequestBodyPageGroup.CurrentPage = NewPage;
	
	SetHeadersByRequestBodyContents();
EndProcedure


&AtClient
Procedure OnChangeRequestAuthenticationType()
	RequestString = CurrentRequestRow();	
	If RequestString = Undefined Then
		Return;
	EndIf;
		
	Types = AuthenticationTypes();
		
	VisibilityAuthenticationSettingsGroups = True;	
	If RequestString.AuthenticationType = Types.Basic Then
		NewPage = Items.BaseAuthenticationPageGroup;
	ElsIf RequestString.AuthenticationType = Types.BearerToken Then
		NewPage = Items.TokenAuthenticationPageGroup;
	ElsIf RequestString.AuthenticationType = Types.NTML Then 
		NewPage = Items.StubAuthenticationPageGroup;
	Else
		VisibilityAuthenticationSettingsGroups = False;
		NewPage = Items.StubAuthenticationPageGroup;
	EndIf;

	Items.AuthenticationTypePageGroup.CurrentPage = NewPage;
	Items.RequestsAuthenticationSettingsGroup.Visible = VisibilityAuthenticationSettingsGroups;
EndProcedure

&AtClient
Function CurrentRequestRow()
	Если UT_CurrentRequestsRowID = Undefined Then
		Return Undefined;
	EndIf;
	Return RequestsTree.FindByID(UT_CurrentRequestsRowID);	
	
EndFunction

// Request body types.
// 
// Return values:
//  Structure -  Request body types:
// * String - String - 
// * BinaryData - String - 
// * File - String - 
&AtClientAtServerNoContext
Function RequestBodyTypes()

	BodyTypes = New Structure;
	BodyTypes.Insert("Bodyless", "Bodyless");	
	BodyTypes.Insert("String", "String");	
	BodyTypes.Insert("BinaryData", "BinaryData");	
	BodyTypes.Insert("File", "File");	
	BodyTypes.Insert("MultypartForm", "MultypartForm");	

	Return BodyTypes;
EndFunction

// Multypart items type.
// 
// Return values:
//  Structure -  Multypart items type:
// * String - String - 
// * File - String - 
&AtClientAtServerNoContext
Function MultypartItemsType()
	Types = New Structure;
	Types.Insert("String", "String");
	Types.Insert("File", "File");
	
	Return Types;
EndFunction

// Types of HTTP methods.
// 
// Return values:
//  Structure -  Types of HTTP methods:
// * GET - String - 
// * POST - String - 
// * PUT - String - 
// * PATCH - String - 
// * DELETE - String - 
// * OPTIONS - String - 
// * HEAD - String - 
&AtClientAtServerNoContext
Function TypesOfHTTPMethods()
	Types = New Structure;
	Types.Insert("GET", "GET");
	Types.Insert("POST", "POST");
	Types.Insert("PUT", "PUT");
	Types.Insert("PATCH", "PATCH");
	Types.Insert("DELETE", "DELETE");
	Types.Insert("OPTIONS", "OPTIONS");
	Types.Insert("HEAD", "HEAD");
	
	Return Types;
EndFunction

&AtClientAtServerNoContext
Function TextContentTypes()
	Types = New Structure;
	Types.Insert("json", "application/json");
	Types.Insert("xml", "application/xml");
	Types.Insert("yaml", "text/yaml");
	Types.Insert("text", "text/plain");

	Return Types;	
EndFunction

&AtClientAtServerNoContext
Function AuthenticationTypes()
	Types = New Structure;
	Types.Insert("None", "None");
	Types.Insert("Basic", "Basic");
	Types.Insert("BearerToken", "BearerToken");
	Types.Insert("NTML", "NTML");
	
	Return Types;
EndFunction

#Region RequestTreeParameters



&AtClient
Function PrepareParameterString()
//		стрParameters = "";
//		
//	For Each стрПараметра In URLParameters Do
//		Если стрПараметра.Using Then
//			Если ПустаяСтрока(стрParameters) Then
//				стрParameters = StrTemplate("%1=%2", стрПараметра.Name, стрПараметра.Value);
//			Else
//				стрParameters = стрParameters+"&"+StrTemplate("%1=%2", стрПараметра.Name, стрПараметра.Value);
//			EndIf;
//		EndIf;
//	EndDo;
//	
//	Return стрParameters;
Return "";
EndFunction

#EndRegion

#Region RequestsFile

// Working on loading a file with reports from the address.
&AtClient
Procedure ProcessingDownloadsFromAddresses(Address)

	LoadFileConsoleНаСервере(Address);
	UpdateTitle();
	
EndProcedure

&AtServer
Procedure FillRequestsFromFile(FileRequest, CollectionRequestItems, FormatVersion)
	NewRequestsRow = CollectionRequestItems.Add();
	NewRequestsRow.Name = FileRequest.Name;
	NewRequestsRow.RequestURL = FileRequest.RequestURL;
	NewRequestsRow.BodyType = FileRequest.BodyType;
	NewRequestsRow.HTTPRequest = FileRequest.HTTPRequest;
	NewRequestsRow.BodyFileName = FileRequest.BodyFileName;
	NewRequestsRow.UseBOM = FileRequest.UseBOM;
	NewRequestsRow.BodyEncoding = FileRequest.BodyEncoding;
	NewRequestsRow.UseProxy = FileRequest.UseProxy;
	NewRequestsRow.ProxyOSAuthentication = FileRequest.ProxyOSAuthentication;
	NewRequestsRow.ProxyPassword = FileRequest.ProxyPassword;
	NewRequestsRow.ProxyUser = FileRequest.ProxyUser;
	NewRequestsRow.ProxyPort = FileRequest.ProxyPort;
	NewRequestsRow.ProxyServer = FileRequest.ProxyServer;
	NewRequestsRow.Timeout = FileRequest.Timeout;
	NewRequestsRow.BodyString = FileRequest.BodyString;
	NewRequestsRow.BodyBinaryData = Undefined;
	NewRequestsRow.TypeOfStringContent = FileRequest.TypeOfStringContent;
	NewRequestsRow.Comment = FileRequest.Comment;

	If FormatVersion >= 3 Then
		NewRequestsRow.AtClient = FileRequest.AtClient;
	EndIf;

	// Authentication
	NewRequestsRow.AuthenticationType = FileRequest.AuthenticationType;
	NewRequestsRow.UseAuthentication = FileRequest.UseAuthentication;
	NewRequestsRow.AuthenticationPassword = FileRequest.AuthenticationPassword;
	NewRequestsRow.AuthenticationUser = FileRequest.AuthenticationUser;
	NewRequestsRow.AuthenticationHeaderName = FileRequest.AuthenticationHeaderName;
	NewRequestsRow.AuthenticationTokenPrefix = FileRequest.AuthenticationTokenPrefix;
	

	If FileRequest.BodyBinaryData <> Undefined Then
		Try
			Storage = ValueFromStringInternal(FileRequest.BodyBinaryData); // ValueStorage
			BinaryData = Storage.Get();
			NewRequestsRow.BodyBinaryData = UT_Common.ValueStorageContainerBinaryData(BinaryData);
		Except
			UT_CommonClientServer.MessageToUser(NStr("ru = 'Для запроса'; en = 'For request'")
				+ " " + NewRequestsRow.Name
				+ NStr("ru = ' не удалось прочитать двоичные данные тела запроса'; en = ' failed to read request body binary data'"));
		EndTry;
	EndIf;

	For Each CurrentHeader In FileRequest.Headers Do
		NewRow = NewRequestsRow.Headers.Add();
		NewRow.Using = CurrentHeader.Using;
		NewRow.Key = CurrentHeader.Key;
		NewRow.Value = CurrentHeader.Value;
	EndDo;	
	
	For Each CurrentHeader In FileRequest.URLParameters Do
		NewRow = NewRequestsRow.URLParameters.Add();
		NewRow.Using = CurrentHeader.Using;
		NewRow.Name = CurrentHeader.Name;
		NewRow.Value = CurrentHeader.Value;
	EndDo;	

	For Each CurrentDescription In FileRequest.MultipartBody Do
		NewRow = NewRequestsRow.MultipartBody.Add();
		NewRow.Using = CurrentDescription.Using;
		NewRow.Name = CurrentDescription.Name;
		NewRow.Type = CurrentDescription.Type;
		NewRow.Value = CurrentDescription.Value;
	EndDo;

	RowCollection = NewRequestsRow.GetItems();
	For Each SubordinateRequest In FileRequest.Rows Do
		FillRequestsFromFile(SubordinateRequest, RowCollection, FormatVersion)
	EndDo;

EndProcedure



// Upload file console on server.
//
// Parameters:
//  Address - String - address of the storage from which you need to download the file.
&AtServer
Procedure LoadFileConsoleНаСервере(Address)
	
	FileData = GetFromTempStorage(Address);

	JSONReader = New JSONReader;
	JSONReader.OpenStream(FileData.OpenStreamForRead());

	FileStructure = ReadJSON(JSONReader);
	JSONReader.Close();

	RequestsElements =  RequestsTree.GetItems();
	RequestsElements.Clear();
	
	For Each CurrentRequest In FileStructure.Requests Do
		FillRequestsFromFile(CurrentRequest, RequestsElements, FileStructure.FormatVersion);	
	EndDo;

EndProcedure

&AtClient
Procedure LoadFileConsoleAfterPutingFile(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	UT_CurrentRequestsRowID = Undefined;
	RequestsFileName = Result.FileName;
	ProcessingDownloadsFromAddresses(Result.Url);
	
	Modified = False;
EndProcedure

// Upload file.
//
// Parameters:
//  NoFileChosing - Boolean
&AtClient
Procedure LoadFileConsole(NoFileChosing = False)

	UT_CommonClient.ReadConsoleFromFile("HTTPRequestConsole",
									SavedFileDescriptionStructure(),
									New CallbackDescription("LoadFileConsoleAfterPutingFile",
															ThisObject),
									NoFileChosing);

EndProcedure

// Completing the file open handler.
// 
// Parameters:
//  ResultQuestion - DialogReturnCode 
//  AdditionalParameters - Arbitrary
&AtClient
Procedure OpenReportFileFinish(ResultQuestion, AdditionalParameters) Export

	Если ResultQuestion = DialogReturnCode.No Then
		Return;
	EndIf;
	LoadFileConsole();
	
EndProcedure

&AtClient
Procedure InitializeConsole()
	Modified = False;
	RequestsFileName = "";

	RequestsTree.GetItems().Clear();
	InitializeRequestsTree();

	UpdateTitle();
EndProcedure

// Completing the handler for creating a new request file.
// 
// Parameters:
//  ResultQuestion - DialogReturnCode
//  AdditionalParameters - Arbitrary
&AtClient
Procedure NewRequestFileFinish(ResultQuestion, AdditionalParameters) Export

	Если ResultQuestion = DialogReturnCode.No Then
		Return;
	EndIf;

	InitializeConsole();

EndProcedure

// Completing the file open handler.
// 
// Parameters:
//  Result - String
//  AdditionalParameters - Arbitrary
&AtClient
Procedure SaveToFileFinish(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;

	RequestsFileName = Result;
	Modified = False;
	UpdateTitle();

	If AdditionalParameters <> Undefined Then
		RunCallback(AdditionalParameters.CallbackDescriptionAboutFinish, True);
	EndIf;
EndProcedure

&AtServer
Function RequestDescriptionToSaveToFile(RequestsTreeRow)
	RequestDescription = New Structure;
	RequestDescription.Insert("Name", RequestsTreeRow.Name);
	RequestDescription.Insert("RequestURL", RequestsTreeRow.RequestURL);
	RequestDescription.Insert("BodyType", RequestsTreeRow.BodyType);
	RequestDescription.Insert("HTTPRequest", RequestsTreeRow.HTTPRequest);
	RequestDescription.Insert("BodyFileName", RequestsTreeRow.BodyFileName);
	RequestDescription.Insert("UseBOM", RequestsTreeRow.UseBOM);
	RequestDescription.Insert("BodyEncoding", RequestsTreeRow.BodyEncoding);
	RequestDescription.Insert("UseProxy", RequestsTreeRow.UseProxy);
	RequestDescription.Insert("ProxyOSAuthentication", RequestsTreeRow.ProxyOSAuthentication);
	RequestDescription.Insert("ProxyPassword", RequestsTreeRow.ProxyPassword);
	RequestDescription.Insert("ProxyUser", RequestsTreeRow.ProxyUser);
	RequestDescription.Insert("ProxyPort", RequestsTreeRow.ProxyPort);
	RequestDescription.Insert("ProxyServer", RequestsTreeRow.ProxyServer);
	RequestDescription.Insert("Timeout", RequestsTreeRow.Timeout);
	RequestDescription.Insert("BodyString", RequestsTreeRow.BodyString);
	RequestDescription.Insert("TypeOfStringContent", RequestsTreeRow.TypeOfStringContent);
	RequestDescription.Insert("Comment", RequestsTreeRow.Comment);
	RequestDescription.Insert("AtClient", RequestsTreeRow.AtClient);

	// Authentication
	RequestDescription.Insert("AuthenticationType", RequestsTreeRow.AuthenticationType);
	RequestDescription.Insert("UseAuthentication", RequestsTreeRow.UseAuthentication);
	RequestDescription.Insert("AuthenticationPassword", RequestsTreeRow.AuthenticationPassword);
	RequestDescription.Insert("AuthenticationUser", RequestsTreeRow.AuthenticationUser);
	RequestDescription.Insert("AuthenticationTokenPrefix", RequestsTreeRow.AuthenticationTokenPrefix);
	RequestDescription.Insert("AuthenticationHeaderName", RequestsTreeRow.AuthenticationHeaderName);
	
	
	Если RequestsTreeRow.BodyBinaryData = Undefined Then
		RequestDescription.Insert("BodyBinaryData", Undefined);
	Else
		BinaryData = UT_Common.ValueFromBinaryDataContainerStorage(RequestsTreeRow.BodyBinaryData);
		RequestDescription.Insert("BodyBinaryData", ValueToStringInternal(New ValueStorage(BinaryData,
			New Deflation(9))));
	EndIf;
	
	RequestDescription.Insert("Headers", New Array);
	
	For Each Str In RequestsTreeRow.Headers Do
		HeaderDescription = New Structure;
		HeaderDescription.Insert("Using", Str.Using);
		HeaderDescription.Insert("Key", Str.Key);
		HeaderDescription.Insert("Value", Str.Value);

		RequestDescription.Headers.Add(HeaderDescription);
	EndDo;
	
	RequestDescription.Insert("URLParameters", New Array);
	For Each Str In RequestsTreeRow.URLParameters Do
		ParameterDescription = New Structure;
		ParameterDescription.Insert("Using", Str.Using);
		ParameterDescription.Insert("Name", Str.Name);
		ParameterDescription.Insert("Value", Str.Value);
		
		RequestDescription.URLParameters.Add(ParameterDescription);
	EndDo;
	
	RequestDescription.Insert("MultipartBody", New Array);
	For Each Str In RequestsTreeRow.MultipartBody Do
		Description = New Structure;
		Description.Insert("Using", Str.Using);
		Description.Insert("Name", Str.Name);
		Description.Insert("Type", Str.Type);
		Description.Insert("Value", Str.Value);
		
		RequestDescription.MultipartBody.Add(Description);
	EndDo;
	
	RequestDescription.Insert("Rows", New Array);
	
	For Each Str In RequestsTreeRow.GetItems() Do
		RequestDescription.Rows.Add(RequestDescriptionToSaveToFile(Str));
	EndDo;

	Return RequestDescription;
EndFunction



&AtServer
Function GetFileDataStringToSaveInFile()
	
	SavedData = New Structure;
	SavedData.Insert("FormatVersion", 3);
	SavedData.Insert("Requests", New Array);
	
	For Each AlgorithmRow In RequestsTree.GetItems() Do
		SavedData.Requests.Add(RequestDescriptionToSaveToFile(AlgorithmRow));
	EndDo;
	
	Return UT_CommonClientServer.mWriteJSON(SavedData);

EndFunction

#EndRegion

#Region RequestExecute 

// Execute request completion of preparatory actions.
// 
// Parameters:
//  СompletionParameters - Structure -  Parameters заврешения:
// * RowID - Number - 
// * AtClient - Boolean -
// * File - Structure: 
// 		** Storage - String - Адрес файла во временном хранилище
// 		** FullName - String 
&AtClient
Procedure ExecuteRequestPreparatoryActionsFinish(СompletionParameters)
	Если СompletionParameters.AtClient Then
		ExecuteRequestAtClient(СompletionParameters.RowID, СompletionParameters.File);
	Else
		ExecuteRequestAtServer(СompletionParameters.RowID, СompletionParameters.File);
	EndIf;
EndProcedure

&AtClient
Procedure ExecuteRequestReadingFilesMultiFinishInTemporaryStorage(Result, AdditionalParameters) Export
	Если Result = Undefined Then
		UT_CommonClientServer.MessageToUser(NStr("ru = 'Не удалось поместить файл тела во временное хранилище'; en = 'Failed to place body file in temporary storage'"));
		Return;
	EndIf;
	
	Если Result.Count() = 0 Then
		UT_CommonClientServer.MessageToUser(NStr("ru = 'Не удалось поместить файл тела во временное хранилище'; en = 'Failed to place body file in temporary storage'"));
		Return;
	EndIf;
	
	
	AdditionalParameters.Insert("File", Result[0]);
	
	ExecuteRequestPreparatoryActionsFinish(AdditionalParameters);
EndProcedure

&AtClient
Procedure ExecuteRequestReadingFilesMultiPartFinishInTemporaryStorage(Result, AdditionalParameters) Export
	If Result = Undefined Then
		UT_CommonClientServer.MessageToUser(NStr("ru = 'Не удалось поместить файлы тела во временное хранилище'; en = 'Failed to put body files into temporary storage'"));
		Return;
	EndIf;
	
	AdditionalParameters.Insert("File", Result);
	
	ExecuteRequestPreparatoryActionsFinish(AdditionalParameters);
EndProcedure

&AtClientAtServerNoContext
Procedure AddListPreviouslyUsedHeadings(Form, Headers)
	For Each KeyValue In Headers Do
		Если Form.ListOfUsedHeaders.FindByValue(KeyValue.Key) = Undefined Then
			Form.ListOfUsedHeaders.Add(KeyValue.Key);
		EndIf;
	EndDo;
EndProcedure

&AtClientAtServerNoContext
Procedure RecordRequestLog(Form, RequestsTreeRow, URLForExecution, RequestURL, Protocol, HTTPRequest,
	HTTPResponse, StartDate, Duration)

	//	Если HTTPResponse = Undefined Then 
	//		Ошибка = True;
	//	Else 
	//		Ошибка=Не ПроверитьУспешностьВыполненияЗапроса(HTTPResponse);//.StatusCode<>КодУспешногоЗапроса;
	//	EndIf;
	LogRecord = RequestsTreeRow.RequestsHistory.Add();
	LogRecord.RequestURL = URLForExecution;

	LogRecord.HTTPFunction = RequestsTreeRow.HTTPRequest;
	LogRecord.RequestURL = RequestURL;
	LogRecord.Date = StartDate;
	LogRecord.ExecutionDuration = Duration;
	LogRecord.Request = HTTPRequest.ResourceAddress;
	LogRecord.RequestHeaders = UT_CommonClientServer.GetHTTPHeadersString(HTTPRequest.Headers);
	LogRecord.BOM = RequestsTreeRow.UseBOM;
	LogRecord.RequestBodyEncoding = RequestsTreeRow.BodyEncoding;
	LogRecord.RequestBodyType = RequestsTreeRow.BodyType;
	LogRecord.Timeout = RequestsTreeRow.Timeout;

	If RequestsTreeRow.BodyType = Form.TypesOfRequestBody.String Then
		LogRecord.RequestBodyString = HTTPRequest.GetBodyAsString();
	ElsIf RequestsTreeRow.BodyType = Form.TypesOfRequestBody.File Then
		LogRecord.RequestBodyFileName = RequestsTreeRow.BodyFileName;
	ElsIf RequestsTreeRow.BodyType = Form.TypesOfRequestBody.Bodyless Then
	Else
		BodyBinaryData = HTTPRequest.GetBodyAsBinaryData();
		LogRecord.RequestBodyBinaryDataAddress = PutToTempStorage(BodyBinaryData,
																	Form.UUID);
		LogRecord.BinaryDataRequestBodyString = String(BodyBinaryData);
	EndIf;

	LogRecord.Protocol = Protocol;

	// Proxy
	LogRecord.UseProxy = RequestsTreeRow.UseProxy;
	LogRecord.ProxyServer = RequestsTreeRow.ProxyServer;
	LogRecord.ProxyPort = RequestsTreeRow.ProxyPort;
	LogRecord.ProxyUser = RequestsTreeRow.ProxyUser;
	LogRecord.ProxyPassword = RequestsTreeRow.ProxyPassword;
	LogRecord.ProxyOSAuthentication = RequestsTreeRow.ProxyOSAuthentication;

	LogRecord.StatusCode = ?(HTTPResponse = Undefined, 500, HTTPResponse.StatusCode);

	If HTTPResponse = Undefined Then
		Return;
	EndIf;

	LogRecord.ResponseHeaders = UT_CommonClientServer.GetHTTPHeadersString(HTTPResponse.Headers);

	ResposeBodyRow = HTTPResponse.GetBodyAsString();
	If ValueIsFilled(ResposeBodyRow) Then
#If Server Then
		If FindDisallowedXMLCharacters(ResposeBodyRow) = 0 Then
			ResponseBodyAddressString = PutToTempStorage(ResposeBodyRow, Form.UUID);
		Else
			ResponseBodyAddressString = PutToTempStorage(NStr("ru = 'Содержит недопустимые символы XML'; en = 'Contains invalid XML characters'"),
														Form.UUID);
		EndIf;
#Else

			Try
				ResponseBodyAddressString = PutToTempStorage(ResposeBodyRow, Form.UUID);
			Except
				ResponseBodyAddressString = PutToTempStorage(NStr("ru = 'Содержит недопустимые символы XML'; en = 'Contains invalid XML characters'"),
															Form.UUID);
			EndTry;
#EndIf
		LogRecord.ResponseBodyAddressString = ResponseBodyAddressString;
	EndIf;
	ResponseBinaryData = HTTPResponse.GetBodyAsBinaryData();
	If ResponseBinaryData <> Undefined Then
		LogRecord.ResponseBodyBinaryDataAddress = PutToTempStorage(ResponseBinaryData,
			Form.UUID);
		LogRecord.ResponseBodyBinaryDataString = String(ResponseBinaryData);
	EndIf;

	ResponseFileName = HTTPResponse.GetBodyFileName();
	If ResponseFileName <> Undefined Then
		File = New File(ResponseFileName);
		If File.Exists() Then
			ResponseBinaryData = New BinaryData(ResponseFileName);
			LogRecord.ResponseBodyBinaryDataAddress = PutToTempStorage(ResponseBinaryData,
				Form.UUID);
			LogRecord.ResponseBodyBinaryDataString = String(ResponseBinaryData);
		EndIf;
	EndIf;
	
	RequestsTreeRow.RequestsHistory.Sort("Date Desc");
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillRequestResultByHistoryRecord(Form, RequestsTreeRow, RequestsHistoryRow = Undefined)
	If RequestsHistoryRow = Undefined Then
		Form.StatusCode = 0;
		Form.ResponseHeaders = "";
		Form.ResponseBodyString = "";
		Form.DurationInMilliseconds = 0;
		Form.ResponseBodyBinaryDataString = "";
		Form.ResponseBodyBinaryDataAddress = "";

		Return;
	EndIf;

	Form.StatusCode = RequestsHistoryRow.StatusCode;
	Form.ResponseHeaders = RequestsHistoryRow.ResponseHeaders;
	If IsTempStorageURL(RequestsHistoryRow.ResponseBodyAddressString) Then
		Form.ResponseBodyString = GetFromTempStorage(RequestsHistoryRow.ResponseBodyAddressString);
	Else
		Form.ResponseBodyString = "";
	EndIf;
	Form.DurationInMilliseconds = RequestsHistoryRow.ExecutionDuration;
	Form.StatusCode = RequestsHistoryRow.StatusCode;
	Form.ResponseBodyBinaryDataString = RequestsHistoryRow.ResponseBodyBinaryDataString;
	Form.ResponseBodyBinaryDataAddress = RequestsHistoryRow.ResponseBodyBinaryDataAddress;
EndProcedure

#EndRegion

#Region RequestsList

&AtClient 
Procedure SaveRequestDataInRequestsTree()
	Если UT_CurrentRequestsRowID = Undefined Then
		Return;
	EndIf;
	CurrentData = RequestsTree.FindByID(UT_CurrentRequestsRowID);
	Если CurrentData = Undefined Then
		Return;
	EndIf;

	// Header 
	CurrentData.Headers.Clear();
	Если EditHeadersWithTable Then
		For Each HeaderRow In RequestHeadersTable Do
			NewRow = CurrentData.Headers.Add();
			NewRow.Key = HeaderRow.Key;
			NewRow.Value = HeaderRow.Value;
			NewRow.Using = HeaderRow.Using;
		EndDo;
	Else
		Headers = UT_CommonClientServer.HTTPRequestHeadersFromString(HeadersString);
		For Each KeyValue In Headers Do
			NewRow = CurrentData.Headers.Add();
			NewRow.Key = KeyValue.Key;
			NewRow.Value = KeyValue.Value;
			NewRow.Using = True;
		EndDo;
	EndIf;
		

//	CurrentData.Text = UT_CodeEditorClient.EditorCodeText(ThisObject, "Code");
//	CurrentData.UseProcessingToExecuteCode = UT_CodeEditorClient.UsageModeDataProcessorToExecuteEditorCode(ThisObject,
//																													"Code");
	
EndProcedure

&AtClient
Procedure ExtractRequestDataFromTreeRow()
	TreeRow = CurrentRequestRow();
	If TreeRow = Undefined Then
		Return;
	EndIf;
	
	// Headers 
	RequestHeadersTable.Clear();
	HeadersString = "";
	If EditHeadersWithTable Then
		For Each Str In TreeRow.Headers Do
			NewRow = RequestHeadersTable.Add();
			FillPropertyValues(NewRow, Str);
		EndDo;
	Else
		HeadersString = HeaderRowByTable(TreeRow.Headers);
	EndIf;
	
	RequestBodyBinaryDataString = "";
	If TreeRow.BodyBinaryData <> Undefined Then
		BinaryDataStorage = TreeRow.BodyBinaryData; // look at UT_CommonClientServer.NewValueStorageBinaryDataType
		RequestBodyBinaryDataString = BinaryDataStorage.Presentation;
	EndIf;

	OnChangeRequestBodyType();
	OnChangeRequestAuthenticationType();

	If TreeRow.RequestsHistory.Count() > 0 Then
		FillRequestResultByHistoryRecord(ThisObject,
												 TreeRow,
												 TreeRow.RequestsHistory[0]);
	Else
		FillRequestResultByHistoryRecord(ThisObject,
												 TreeRow,
												 Undefined);
		
	EndIf;
	SetPreliminaryURL(TreeRow.GetID());
EndProcedure



#EndRegion

#Region RequestPreparing

&AtClientAtServerNoContext
Procedure FillHeadersTableByString(StringHeaders, RequestHeadersTable)
	RequestHeadersTable.Clear();
	
	TextDocument = New TextDocument;
	TextDocument.SetText(StringHeaders);
	For RowNumber = 1 To TextDocument.LineCount() Do
		HeaderStr = TextDocument.GetLine(RowNumber);

		If Not ValueIsFilled(HeaderStr) Then
			Continue;
		EndIf;

		HeaderArray = StrSplit(HeaderStr, ":");
		If HeaderArray.Count() <> 2 Then
			Continue;
		EndIf;

		HC = RequestHeadersTable.Add();
		HC.Key = HeaderArray[0];
		HC.Value = HeaderArray[1];
		HC.Using = True;

	EndDo;
	
EndProcedure

&AtClient
Procedure SetRequestHeaderEditingPage()
	Если EditHeadersWithTable Then
		NewPage = Items.EditRequestHeadersPageGroupAsTable;
	Else
		NewPage = Items.EditRequestHeadersPageGroupAsText;
	EndIf;

	Items.EditRequestHeadersPagesGroup.CurrentPage = NewPage;

	// Now you need to fill in the headings on the new page according to the old page
	Если EditHeadersWithTable Then
		FillHeadersTableByString(HeadersString, RequestHeadersTable);
	Else
		HeadersString = HeaderRowByTable(RequestHeadersTable);
	EndIf;
EndProcedure

#EndRegion

#Region ExecuteRequest

&AtClientAtServerNoContext
Procedure ExecuteRequestAtClientAtServer(Form, TreeRow, BodyFileData = Undefined)
	URLForExecution = URLForExecution(TreeRow);
	StructureURL = UT_HTTPConnector.ParseURL(URLForExecution);

	HTTPConnection = PreparedConnection(Form, TreeRow, StructureURL);

	StartExecution = CurrentUniversalDateInMilliseconds();
	Request = PreparedHTTPRequest(Form, TreeRow, StructureURL, BodyFileData);
	#If AtClient Then
	StartDate = CurrentDate();
	#Else
	StartDate = CurrentSessionDate();
	#EndIf
	
	RequestExecutionResultProcessingParameters = New Structure;
	RequestExecutionResultProcessingParameters.Insert("Form", Form);
	RequestExecutionResultProcessingParameters.Insert("TreeRow", TreeRow);
	RequestExecutionResultProcessingParameters.Insert("HTTPConnection", HTTPConnection);
	RequestExecutionResultProcessingParameters.Insert("Request", Request);
	RequestExecutionResultProcessingParameters.Insert("StartExecution", StartExecution);
	RequestExecutionResultProcessingParameters.Insert("StartDate", StartDate);
	RequestExecutionResultProcessingParameters.Insert("URLForExecution", URLForExecution);
	RequestExecutionResultProcessingParameters.Insert("StructureURL", StructureURL);
	RequestExecutionResultProcessingParameters.Insert("BodyFileData", BodyFileData);
	
#If Client Then
	//@skip-check wrong-string-literal-content
	NotificationAboutRequestFinish = New CallbackDescription("AfterRequestExecutionAtClient", Form,
		RequestExecutionResultProcessingParameters);
#EndIf	
	
	Try
		If UT_CommonClientServer.PlatformVersionNotLess("8.3.21")
			 And TreeRow.AtClient Then
			If TreeRow.HTTPRequest = Form.TypesOfHTTPMethods.GET Then
				Response = HTTPConnection.GetAsync(Request);
			ElsIf TreeRow.HTTPRequest = Form.TypesOfHTTPMethods.POST Then
				Response = HTTPConnection.PostAsync(Request);
			ElsIf TreeRow.HTTPRequest = Form.TypesOfHTTPMethods.DELETE Then
				Response = HTTPConnection.DeleteAsync(Request);
			ElsIf TreeRow.HTTPRequest = Form.TypesOfHTTPMethods.PUT Then
				Response = HTTPConnection.PutAsync(Request);
			ElsIf TreeRow.HTTPRequest = Form.TypesOfHTTPMethods.PATCH Then
				Response = HTTPConnection.PatchAsync(Request);
			Else
				Response = HTTPConnection.CallHTTPMethodAsync(TreeRow.HTTPRequest, Request);
			EndIf;
#If Client Then
			UT_PlatformCompatibilityMethods_8_3_18_Client.SetCallbackDescriptionForPromise(Response,
																NotificationAboutRequestFinish);
			Return;
#EndIf
		Else
			If TreeRow.HTTPRequest = Form.TypesOfHTTPMethods.GET Then
				Response = HTTPConnection.Get(Request);
			ElsIf TreeRow.HTTPRequest = Form.TypesOfHTTPMethods.POST Then
				Response = HTTPConnection.Post(Request);
			ElsIf TreeRow.HTTPRequest = Form.TypesOfHTTPMethods.DELETE Then
				Response = HTTPConnection.Delete(Request);
			ElsIf TreeRow.HTTPRequest = Form.TypesOfHTTPMethods.PUT Then
				Response = HTTPConnection.Put(Request);
			ElsIf TreeRow.HTTPRequest = Form.TypesOfHTTPMethods.PATCH Then
				Response = HTTPConnection.Patch(Request);
			Else
				Response = HTTPConnection.CallHTTPMethod(TreeRow.HTTPRequest, Request);
			EndIf;
			RequestExecutionResultProcessingParameters.Insert("Response", Response);
		EndIf;
	Except
		UT_CommonClientServer.MessageToUser(ErrorDescription());
		
		RequestExecutionResultProcessingParameters.Insert("Response", Undefined);
	EndTry;
	AfterRequestExecutionAtClientAtServer(RequestExecutionResultProcessingParameters);

EndProcedure

&AtClient
Procedure ExecuteRequestAtClient(TreeRowId, BodyFileData = Undefined)
	TreeRow = RequestsTree.FindByID(TreeRowId);
	Если TreeRow = Undefined Then
		Return;
	EndIf;
	
	ExecuteRequestAtClientAtServer(ThisObject, TreeRow, BodyFileData);
	
EndProcedure

&AtServer
Procedure ExecuteRequestAtServer(TreeRowId, BodyFileData = Undefined)
	TreeRow = RequestsTree.FindByID(TreeRowId);
	Если TreeRow = Undefined Then
		Return;
	EndIf;
	
	ExecuteRequestAtClientAtServer(ThisObject, TreeRow, BodyFileData);
EndProcedure

&AtClientAtServerNoContext
Function PreparedConnection(Form, RequestsTreeRow, StructureURL)
	Port = Undefined;
	If ValueIsFilled(StructureURL.Port) Then
		Port = StructureURL.Port;
	EndIf;
		
	ProxySettings = Undefined;
	If RequestsTreeRow.UseProxy Then
#If Not WebClient Then
		ProxySettings = New InternetProxy(True);
		ProxySettings.Установить(StructureURL.Scheme,
								   RequestsTreeRow.ProxyServer,
								   RequestsTreeRow.ProxyPort,
								   RequestsTreeRow.ProxyUser,
								   RequestsTreeRow.ProxyPassword,
								   RequestsTreeRow.ProxyOSAuthentication);
#EndIf
	EndIf;

	UseNTMAuthentication = Undefined;
	If UT_CommonClientServer.PlatformVersionNotLess("8.3.7") Then
		If RequestsTreeRow.UseAuthentication
			 And RequestsTreeRow.AuthenticationType = AuthenticationTypes().NTML Then
			UseNTMAuthentication = True;
		EndIf;
	EndIf;

	SecuredConnection = Undefined;
	If Lower(StructureURL.Scheme) = "https" Then
		SecuredConnection = UT_PlatformCompatibilityMethods_8_3_21_ClientServer.NewOpenSSLSecureConnection();
	EndIf;

	Return UT_PlatformCompatibilityMethods_8_3_21_ClientServer.NewHTTPConnection(StructureURL.Host,
																				   Port,
																				   ,
																				   ,
																				   ProxySettings,
																				   RequestsTreeRow.Timeout,
																				   SecuredConnection,
																				   UseNTMAuthentication);

EndFunction

&AtClientAtServerNoContext
Function PreparedHTTPRequest(Form, RequestsTreeRow, StructureURL, BodyFileData)
	Headers = New Map;

	RequestString = StructureURL.Path;

	ParametersString = "";
	For Each KeyValue In StructureURL.RequestParameters Do
		ParametersString = ParametersString
						   + ?(Not ValueIsFilled(ParametersString), "?", "&")
						   + KeyValue.Key
						   + "="
						   + KeyValue.Value;
	EndDo;

	ResourceAddress = RequestString + ParametersString;
	
	BodyParameters = New Structure;
	BodyParameters.Insert("Body", Undefined);
	BodyParameters.Insert("BodyEncoding", Undefined);
	BodyParameters.Insert("BodyBOM", Undefined);
	
	If RequestsTreeRow.BodyType = Form.TypesOfRequestBody.Bodyless Then
		// We don't do anything. no body
	ElsIf RequestsTreeRow.BodyType = Form.TypesOfRequestBody.String Then
		If ValueIsFilled(RequestsTreeRow.BodyString) Then
#If WebClient Then
			BOM = Undefined;
			If RequestsTreeRow.UseBOM <> 0 Then
				UT_CommonClientServer.MessageToUser(NStr("ru = 'Настройка использования BOM игнорируется на веб клиенте'; en = 'Setting to use BOM is ignored on the web client'"));
			EndIf;
#Else
				If RequestsTreeRow.UseBOM = 0 Then
					BOM = ByteOrderMarkUse.Auto;
				ElsIf (RequestsTreeRow.UseBOM = 1) Then
					BOM = ByteOrderMarkUse.Use;
				Else
					BOM = ByteOrderMarkUse.DontUse;
				EndIf;
#EndIf                
			BodyParameters.BodyBOM = BOM;
			WithoutTextEncoding = RequestsTreeRow.BodyEncoding = "Auto";
#If WebClient Then
			If Not WithoutTextEncoding Then
				WithoutTextEncoding = True;
				UT_CommonClientServer.MessageToUser(NStr("ru = 'При запросе в вебклиенте тело устанавливается в кодровке UTF-8 и настройка кодировки игнорируется'; en = 'When requesting in the web client, the body is set to UTF-8 encoding and the encoding setting is ignored'"));
			EndIf;

#EndIf
			BodyParameters.Body = RequestsTreeRow.BodyString;

			If Not WithoutTextEncoding Then
				Try
					BodyEncoding = UT_PlatformCompatibilityMethods_8_3_21_ClientServer.TextEncodingByName(RequestsTreeRow.BodyEncoding);
				Except
					BodyEncoding = RequestsTreeRow.BodyEncoding;
				EndTry;
				BodyParameters.BodyEncoding = BodyEncoding;
			EndIf;
		EndIf;
	ElsIf RequestsTreeRow.BodyType = Form.TypesOfRequestBody.BinaryData Then
		If RequestsTreeRow.BodyBinaryData <> Undefined Then
			BodyBinaryData = UT_Common.ValueFromBinaryDataContainerStorage(RequestsTreeRow.BodyBinaryData);
			
			If TypeOf(BodyBinaryData) = Type("BinaryData") Then 
				BodyParameters.Body = BodyBinaryData;	
			EndIf;
		EndIf;
	ElsIf RequestsTreeRow.BodyType = Form.TypesOfRequestBody.MultypartForm Then
		MultypartItemsType = MultypartItemsType();
		RowDelimiterForMultipartRequest = RowDelimiterForMultipartRequest();
		
		FilesToCombine = New Array;
		For RowIndex = 0 To RequestsTreeRow.MultipartBody.Count() - 1 Do
			MultypartItemRow = RequestsTreeRow.MultipartBody[RowIndex];
			If Not MultypartItemRow.Using Then
				Continue;
			EndIf;
			
			If MultypartItemRow.Type = MultypartItemsType.String Then

				InputFile = ""
							+ RowDelimiterForMultipartRequest
							+ "--"
							+ Form.MultipartBodySplitter
							+ RowDelimiterForMultipartRequest
							+ "Content-Disposition: form-data;name="""
							+ MultypartItemRow.Name
							+ """"
							+ RowDelimiterForMultipartRequest 
							+ RowDelimiterForMultipartRequest;

				FilesToCombine.Add(GetBinaryDataFromString(InputFile));

				FilesToCombine.Add(GetBinaryDataFromString(MultypartItemRow.Value));

			ElsIf MultypartItemRow.Type = MultypartItemsType.File Then
				If Not ValueIsFilled(MultypartItemRow.Value) Then
					Continue;
				EndIf;

				BinaryDataAddress = BodyFileData[RowIndex];
				If BinaryDataAddress = Undefined Then
					Continue;
				EndIf;
				If Not IsTempStorageURL(BinaryDataAddress) Then
					Continue;
				EndIf;


				File = New File(MultypartItemRow.Value);

				InputFile = ""
							  + RowDelimiterForMultipartRequest
							  + "--"
							  + Form.MultipartBodySplitter
							  + RowDelimiterForMultipartRequest
							  + "Content-Disposition: form-data;name="""
							  + MultypartItemRow.Name
							  + """;filename="""
							  + File.Name
							  + """"
							  + RowDelimiterForMultipartRequest
							  + "Content-Type: application/octet-stream"
							  + RowDelimiterForMultipartRequest
							  + RowDelimiterForMultipartRequest;

				FilesToCombine.Add(GetBinaryDataFromString(InputFile));
				FilesToCombine.Add(GetFromTempStorage(BinaryDataAddress));
			EndIf;
				
		EndDo;

		InputFile = ""
					  + RowDelimiterForMultipartRequest
					  + "--"
					  + Form.MultipartBodySplitter
					  + "--"
					  + RowDelimiterForMultipartRequest;

		FilesToCombine.Add(GetBinaryDataFromString(InputFile));

		FinalBD = ConcatBinaryData(FilesToCombine);

		SendFileSize = Format(FinalBD.Size(), "NG=0;");
		BodyParameters.Body = FinalBD;
		
		Headers.Insert("Content-Length", SendFileSize);		
	Else
		If RequestsTreeRow.AtClient Then      
			BodyParameters.Body = BodyFileData.FullName;
		Else
#If Not WebClient Then
			BodyBinaryData = GetFromTempStorage(BodyFileData.Storage);
			If TypeOf(BodyBinaryData) = Тип("BinaryData") Then
				File = New File(RequestsTreeRow.BodyFileName);
			//@skip-check missing-temporary-file-deletion
				TemporaryFile = GetTempFileName(File.Extension);
				BodyBinaryData.Write(TemporaryFile);

				BodyParameters.Body = TemporaryFile;

				Headers.Insert("Content-Length", Format(BodyBinaryData.Размер(), "NG=0;"));

			EndIf;
#EndIf
		EndIf;
	EndIf;

	// Now you need to set the request headers

	For Each HeaderRow In RequestsTreeRow.Headers Do
		If Not HeaderRow.Using Then
			Continue;
		EndIf;
		Headers.Insert(HeaderRow.Key, HeaderRow.Value);
	EndDo;

	SetAuthenticationHeaderInHTTPRequest(RequestsTreeRow, Headers);
	NewRequest = UT_PlatformCompatibilityMethods_8_3_21_ClientServer.NewHTTPRequest(ResourceAddress, Headers);
	
	If RequestsTreeRow.BodyType = Form.TypesOfRequestBody.String Then
		If BodyParameters.BodyEncoding = Undefined Then
			//@skip-check unknown-method-property
			NewRequest.SetBodyFromString(BodyParameters.Body, , BodyParameters.BodyBOM);
		Else
			//@skip-check unknown-method-property
			NewRequest.SetBodyFromString(BodyParameters.Body, BodyParameters.BodyEncoding, BodyParameters.BodyBOM);
		EndIf;
	ElsIf RequestsTreeRow.BodyType = Form.TypesOfRequestBody.BinaryData Then
		If TypeOf(BodyParameters.Body) = Type("BinaryData") Then
			//@skip-check unknown-method-property
			NewRequest.SetBodyFromBinaryData(BodyParameters.Body);
		EndIf;
	ElsIf RequestsTreeRow.BodyType = Form.TypesOfRequestBody.MultypartForm Then
		//@skip-check unknown-method-property
		NewRequest.SetBodyFromBinaryData(BodyParameters.Body);
	ElsIf RequestsTreeRow.BodyType = Form.TypesOfRequestBody.File Then
		If BodyParameters.Body <> Undefined Then
			//@skip-check unknown-method-property
			NewRequest.SetBodyFileName(BodyParameters.Body);
		EndIf;
	EndIf;
	Return NewRequest;
EndFunction

&AtClientAtServerNoContext
Procedure SetAuthenticationHeaderInHTTPRequest(RequestsTreeRow, RequestHeaders)
	Types = AuthenticationTypes();
	If Not ValueIsFilled(RequestsTreeRow.AuthenticationType)
		 Or RequestsTreeRow.AuthenticationType = Types.None Then
		Return;
	EndIf;
	
	If Not RequestsTreeRow.UseAuthentication Then
		Return;
	EndIf;
	
	HeaderName = "Authorization";
	If RequestHeaders.Get(HeaderName) <> Undefined Then
		Return;
	EndIf;
	
	HeaderValue = "";
	
	Если RequestsTreeRow.AuthenticationType = Types.Basic Then
		Prefix = "Basic";

		HeaderValue = Prefix
							+ " "
							+ Base64Строка(GetBinaryDataFromString(RequestsTreeRow.AuthenticationUser
							+ ":"
							+ RequestsTreeRow.AuthenticationPassword));

	ElsIf RequestsTreeRow.AuthenticationType = Types.BearerToken Then 
		Prefix = TrimAll(RequestsTreeRow.AuthenticationTokenPrefix);
		If Not ValueIsFilled(Prefix) Then
			Prefix = "Bearer";
		EndIf;
		HeaderValue = Prefix + " " + RequestsTreeRow.AuthenticationPassword;
	Else
		Return;
	EndIf;
	
	RequestHeaders.Insert(HeaderName, HeaderValue);
EndProcedure

// После выполнения запроса на клиенте на сервере.
// 
// Parameters:
//  AdditionalParameters - Structure -  Дополнительные параметры:
// * Form - УправляемаяФорма - 
// * TreeRow - FormDataTreeItem - 
// * HTTPConnection - HTTPСоединение - 
// * Request - HTTPRequest - 
// * StartExecution - Number - 
// * StartDate - Date - 
// * URLForExecution - String -
// * StructureURL - Structure - :
// ** Scheme - String - 
// ** Аутентификация - Structure - :
// *** Пользователь - String - 
// *** Пароль - String - 
// ** Сервер - String - 
// ** Port - Number - 
// ** Path - Строка, Number - 
// ** RequestParameters - Map - 
// ** Фрагмент - String - 
// * BodyFileData - Structure, Undefined - :
// ** Storage - String - 
// ** FullName - String - 
// * Response - HTTPResponse - 
&AtClientAtServerNoContext
Procedure AfterRequestExecutionAtClientAtServer(AdditionalParameters)
	FinishExecution = CurrentUniversalDateInMilliseconds();

	DurationInMilliseconds = FinishExecution - AdditionalParameters.StartExecution;

	RecordRequestLog(AdditionalParameters.Form,
							AdditionalParameters.TreeRow,
							AdditionalParameters.URLForExecution,
							AdditionalParameters.StructureURL.Host,
							AdditionalParameters.StructureURL.Scheme,
							AdditionalParameters.Request,
							AdditionalParameters.Response,
							AdditionalParameters.StartDate,
							DurationInMilliseconds);

	FillRequestResultByHistoryRecord(AdditionalParameters.Form,
							AdditionalParameters.TreeRow,
							AdditionalParameters.TreeRow.RequestsHistory[0]);

	AddListPreviouslyUsedHeadings(AdditionalParameters.Form,
							AdditionalParameters.Request.Headers);

	BodyFileName = AdditionalParameters.Request.GetBodyFileName();
	Если BodyFileName <> Undefined Then
		//@skip-check empty-except-statement
		Try
			DeleteFiles(BodyFileName);
		Except
		EndTry;
	EndIf;
	Если AdditionalParameters.BodyFileData <> Undefined Then
		Если TypeOf(AdditionalParameters.BodyFileData) = Type("Structure") Then
		//@skip-check empty-except-statement
			Try
				DeleteFromTempStorage(AdditionalParameters.BodyFileData.Storage);
			Except
			EndTry;
		ElsIf TypeOf(AdditionalParameters.BodyFileData) = Type("Map") Then
			For Each KeyValue In AdditionalParameters.BodyFileData Do
			//@skip-check empty-except-statement
				Try
					DeleteFromTempStorage(KeyValue.Value);
				Except
				EndTry;
			EndDo;
		EndIf;
	EndIf;
	
	
EndProcedure

&AtClient 
Procedure AfterRequestExecutionAtClient(ServerResponse, AdditionalParameters) Export
	If TypeOf(ServerResponse) = Type("ErrorInfo") Then
		UT_CommonClientServer.MessageToUser(ServerResponse.Описание);
		Response = Undefined;
	Else
		Response = ServerResponse;
	EndIf;
		
	AdditionalParameters.Insert("Response", Response);
	
	AfterRequestExecutionAtClientAtServer(AdditionalParameters);	
EndProcedure

#EndRegion

#Region RequestResult

#EndRegion

#Region General

&AtServerNoContext
Function URLForExecutionWithEncodedParameters(URL, Parameters)
	Return UT_HTTPConnector.UI_PreparedURL(URL, Parameters);
EndFunction

&AtClientAtServerNoContext
Function URLForExecution(RequestsTreeRow)
	URLParameters = New Map;
	
	For Each Str In RequestsTreeRow.URLParameters Do
		If Not Str.Using Then
			Continue;
		EndIf;
		If Not ValueIsFilled(Str.Name) Then
			Continue;
		EndIf;
		
		NameArray = URLParameters[Str.Name];
		If NameArray = Undefined Then
			URLParameters.Insert(Str.Name, New Array);
			NameArray = URLParameters[Str.Name];
		EndIf;
		NameArray.Add(Str.Value);
	EndDo;
	
	Return URLForExecutionWithEncodedParameters(RequestsTreeRow.RequestURL, URLParameters);
EndFunction

&AtServer
Procedure SetPreliminaryURL(TreeRowId)
	PreliminaryURL = "";
	If TreeRowId = Undefined Then
		Return;
	EndIf;
	
	CurrentTreeRow = RequestsTree.FindByID(TreeRowId);
	If CurrentTreeRow = Undefined Then
		Return;
	EndIf;
		
	PreliminaryURL = URLForExecution(CurrentTreeRow)
EndProcedure

&AtClientAtServerNoContext
Function RowDelimiterForMultipartRequest()
	Return Chars.CR + Chars.LF;
EndFunction

&AtClient
Function PossibleRequestExecution(RequestRow)
	If Not RequestRow.AtClient Then
		Return True;
	EndIf;	
	
	If Not UT_CommonClient.IsWebClient() Then
		Return True;
	EndIf;		
	
	Result = True;

	If Not UT_CommonClientServer.PlatformVersionNotLess("8.3.21") Then
		UT_CommonClientServer.MessageToUser(NStr("ru = 'Запросы в контексте веб-клиента доступны, начиная с версии платформы 8.3.21'; en = 'Requests in the context of the web client are available starting from platform version 8.3.21'"));
		Result = False;
	EndIf;

	If RequestRow.UseProxy Then
		UT_CommonClientServer.MessageToUser(NStr("ru = 'В веб клиенте не поддерживается использование прокси в HTTP запросах'; en = 'The web client does not support the use of proxies in HTTP requests'"));
		Result = False;
	EndIf;
	
	Return Result;
EndFunction

&AtClientAtServerNoContext
Function HeaderRowByTable(HeaderTable)
	HeadersStringsArray = New Array;
	For Each Str In HeaderTable Do
		If Not Str.Using Then
			Continue;
		EndIf;
		HeadersStringsArray.Add(Str.Key + ":" + Str.Value);
	EndDo;

	Return StrConcat(HeadersStringsArray, Chars.LF);

EndFunction

&AtClientAtServerNoContext
Function RequestBodyEncodingsTypes()
	Types = New Structure;
	Types.Insert("Auto", "Auto");
	Types.Insert("System", "System");
	Types.Insert("ANSI", "ANSI");
	Types.Insert("OEM", "OEM");
	Types.Insert("UTF8", "UTF8");
	Types.Insert("UTF16", "UTF16");
	
	
	Return Types;
EndFunction

&AtServer
Procedure FillChoiceListListOfTextEncodings()
	Items.RequestBodyEncoding.ChoiceList.Clear();

	Types = RequestBodyEncodingsTypes();
	For Each KeyValue In Types Do
		Items.RequestBodyEncoding.ChoiceList.Add(KeyValue.Value);	
	EndDo;
	
EndProcedure

&AtServer
Procedure InitializeForm()
	MultipartBodySplitter = "X-TOOLS-UI-1C-BOUNDARY";
	
	FillChoiceListListOfTextEncodings();
	
	Items.RequestBodyType.ChoiceList.Clear();
	TypesOfRequestBody = RequestBodyTypes();
	Items.RequestBodyType.ChoiceList.Add(TypesOfRequestBody.Bodyless, "Bodyless");
	Items.RequestBodyType.ChoiceList.Add(TypesOfRequestBody.String);
	Items.RequestBodyType.ChoiceList.Add(TypesOfRequestBody.BinaryData, "Binary data");
	Items.RequestBodyType.ChoiceList.Add(TypesOfRequestBody.File);
	Items.RequestBodyType.ChoiceList.Add(TypesOfRequestBody.MultypartForm, "Multipart form");

	TypesOfHTTPMethods = TypesOfHTTPMethods();
	Items.HTTPRequest.ChoiceList.Clear();
	For Each KeyValue In TypesOfHTTPMethods Do
		Items.HTTPRequest.ChoiceList.Add(KeyValue.Value);
	EndDo;
	
	TypesStringContentBody = TextContentTypes();
	Items.RequestsTreeTypeOfStringContent.ChoiceList.Clear();
	Items.RequestsTreeTypeOfStringContent.ChoiceList.Add("None");
	For Each KeyValue In TypesStringContentBody Do
		Items.RequestsTreeTypeOfStringContent.ChoiceList.Add(KeyValue.Key);
	EndDo;
	
	Items.RequestsTreeAuthenticationType.ChoiceList.Clear();
	
	AuthenticationTypes = AuthenticationTypes();
	Items.RequestsTreeAuthenticationType.ChoiceList.Add(AuthenticationTypes.None);
	Items.RequestsTreeAuthenticationType.ChoiceList.Add(AuthenticationTypes.Basic, NStr("ru = 'Базовая(Логин,Пароль)'; en = 'Basic(Login,Password)'"));
	Items.RequestsTreeAuthenticationType.ChoiceList.Add(AuthenticationTypes.BearerToken, NStr("ru = 'Bearer Токен'; en = 'Bearer Token'"));
	Если UT_CommonClientServer.PlatformVersionNotLess("8.3.7") Then
		Items.RequestsTreeAuthenticationType.ChoiceList.Add(AuthenticationTypes.NTML, NStr("ru = 'NTML (аутентифкация ОС)'; en = 'NTML (OS authentication)'"));
	EndIf;
	
	Items.MultipartBodyRequestsTreeType.ChoiceList.Clear();
	
	MultypartItemsType = MultypartItemsType();
	Items.MultipartBodyRequestsTreeType.ChoiceList.Add(MultypartItemsType.String);
	Items.MultipartBodyRequestsTreeType.ChoiceList.Add(MultypartItemsType.File);
		
	InitializeRequestsTree();	

EndProcedure


&AtServer
Procedure InitializeRequestsTree()
	TreeItems = RequestsTree.GetItems();
	If TreeItems.Count() > 0 Then
		Return;
	EndIf;
	
	NewRow = TreeItems.Add();
	InitializeRequestsTreeString(NewRow, ThisObject);
EndProcedure


&AtClientAtServerNoContext
Procedure InitializeRequestsTreeString(RequestsTreeRow, Form)
	RequestsTreeRow.HTTPRequest = Form.TypesOfHTTPMethods.GET;
	RequestsTreeRow.BodyType = Form.TypesOfRequestBody.Bodyless;
	
	RequestBodyEncodingsTypes = RequestBodyEncodingsTypes();
	RequestsTreeRow.BodyEncoding = RequestBodyEncodingsTypes.Auto;
	
	RequestsTreeRow.Timeout = 30;
	RequestsTreeRow.TypeOfStringContent = "None";
	
	If Not ValueIsFilled(RequestsTreeRow.Name) Then
		RequestsTreeRow.Name = "Request" + Format(RequestsTreeRow.GetID(), "NG=0;");
	EndIf;
	
	AuthenticationTypes = AuthenticationTypes();
	RequestsTreeRow.AuthenticationType = AuthenticationTypes.None;
	
EndProcedure



// Update form title.
&AtClient
Procedure UpdateTitle()

	Title = InitialHeader + ?(RequestsFileName <> "", ": " + RequestsFileName, "");

EndProcedure


#EndRegion


&AtServer
Procedure FillBodyBinaryDataFromFileFinishAtServer(Address, RowID)
	CurrentData = RequestsTree.FindByID(RowID);
	If CurrentData = Undefined Then
		Return;
	EndIf;

	BinaryData = GetFromTempStorage(Address);

	CurrentData.BodyBinaryData = UT_Common.ValueStorageContainerBinaryData(BinaryData);

	RequestBodyBinaryDataString = CurrentData.BodyBinaryData.Presentation;	
EndProcedure

&AtClient
Procedure FillBodyBinaryDataFromFileFinish(Result, Address, ChosenFileName, AdditionalParameters) Export
	If Not Result Then
		Return;
	EndIf;

	FillBodyBinaryDataFromFileFinishAtServer(Address, AdditionalParameters.CurrentRowID);

EndProcedure

// Request body file name start choose finish.
// 
// Parameters:
//  ChosenFiles - Array of String - Chosen fales
//  AdditionalParameters - Structure:
//  * RowID - Number
&AtClient
Procedure RequestBodyFileNameStartChooseFinish(ChosenFiles, AdditionalParameters) Export

	If ChosenFiles = Undefined Then
		Return;
	EndIf;

	If ChosenFiles.Count() = 0 Then
		Return;
	EndIf;

	RequestString = RequestsTree.FindByID(AdditionalParameters.RowID);
	If RequestString = Undefined Then
		Return;
	EndIf;

	RequestString.BodyFileName = ChosenFiles[0];
EndProcedure

&AtServer
Procedure FillByDebaggingData(DebuggingDataAddress)
	TreeItems = RequestsTree.GetItems();
	TreeItems.Clear();
	
	RequestNewRow = TreeItems.Add();
	InitializeRequestsTreeString(RequestNewRow, ThisObject);
	RequestNewRow.Name = "Debugging";
	
	DebuggingData = GetFromTempStorage(DebuggingDataAddress);

	RequestNewRow.RequestURL = "";
	If Not ValueIsFilled(DebuggingData.Protocol) Then
		RequestNewRow.RequestURL = "http";
	Else
		RequestNewRow.RequestURL = DebuggingData.Protocol;
	EndIf;

	RequestNewRow.RequestURL = RequestNewRow.RequestURL + "://" + DebuggingData.RequestURL;

	If ValueIsFilled(DebuggingData.Port) Then
		SpecialPort = True;
		If (Not ValueIsFilled(DebuggingData.Protocol) Or DebuggingData.Protocol = "http")
			 И DebuggingData.Port = 80 Then
			SpecialPort = False;
		ElsIf DebuggingData.Protocol = "https" And DebuggingData.Port = 443 Then
			SpecialPort = False;
		EndIf;

		If SpecialPort Then
			RequestNewRow.RequestURL = RequestNewRow.RequestURL + ":" + Format(DebuggingData.Port, "NG=0;");
		EndIf;
	EndIf;

	If Not StrStartsWith(DebuggingData.Request, "/") Then
		RequestNewRow.RequestURL = RequestNewRow.RequestURL + "/";
	EndIf;

	RequestNewRow.RequestURL = RequestNewRow.RequestURL + DebuggingData.Request;

	EditHeadersWithTable = True;
	Items.EditRequestHeadersPagesGroup.CurrentPage = Items.EditRequestHeadersPageGroupAsTable;

	Headers = DebuggingData.Headers;

	//Removing unused characters from headers string
	SymbolPosition = FindDisallowedXMLCharacters(Headers);
	While  SymbolPosition > 0 Do
		If SymbolPosition = 1 Then
			Headers = Mid(Headers, 2);
		ElsIf SymbolPosition = StrLen(Headers) Then
			Headers = Left(Headers, StrLen(Headers) - 1);
		Else
			NewHeaders = Left(Headers, SymbolPosition - 1) + Mid(Headers, SymbolPosition + 1);
			Headers = NewHeaders;
		EndIf;

		SymbolPosition = FindDisallowedXMLCharacters(Headers);
	EndDo;

	FillHeadersTableByString(Headers, RequestNewRow.Headers);
	FillBodyRequestByDebugData(RequestNewRow, DebuggingData);
	FillAuthenticationByDebugData(RequestNewRow, DebuggingData);

	If ValueIsFilled(DebuggingData.ProxyServer) Then
		RequestNewRow.UseProxy = True;

		RequestNewRow.ProxyServer = DebuggingData.ProxyServer;
		RequestNewRow.ProxyPort = DebuggingData.ProxyPort;
		RequestNewRow.ProxyUser = DebuggingData.ProxyUser;
		RequestNewRow.ProxyPassword = DebuggingData.ProxyPassword;
		RequestNewRow.ProxyOSAuthentication = DebuggingData.UseOSAuthentication;
	EndIf;

EndProcedure

&AtServer
Procedure FillBodyRequestByDebugData(RequestNewRow, DebuggingData)

	If DebuggingData.RequestBody <> Undefined Then
		If FindDisallowedXMLCharacters(DebuggingData.RequestBody) = 0 Then
			RequestNewRow.BodyType = TypesOfRequestBody.String;
			RequestNewRow.BodyString = DebuggingData.RequestBody;
			Return;
		EndIf;
	EndIf;

	If DebuggingData.Property("BodyBinaryData") Then
		If TypeOf(DebuggingData.BodyBinaryData) = Type("BinaryData") Then
			RequestNewRow.BodyType = TypesOfRequestBody.BinaryData;
			RequestNewRow.BodyBinaryData = UT_Common.ValueStorageContainerBinaryData(DebuggingData.BodyBinaryData);
			Return;
		EndIf;
	EndIf;
	If DebuggingData.Property("RequestFileName") Then
		RequestNewRow.BodyType = TypesOfRequestBody.File;
		RequestNewRow.BodyFileName = DebuggingData.RequestFileName;
		Return;
	EndIf;

	RequestNewRow.BodyType = TypesOfRequestBody.Bodyless;
EndProcedure

&AtServer
Procedure FillAuthenticationByDebugData(RequestNewRow, DebuggingData)
	AuthenticationTypes = AuthenticationTypes();
	If DebuggingData.Property("ConnectionUseOSAuthentication") Then
		If DebuggingData.ConnectionUseOSAuthentication Then
			RequestNewRow.AuthenticationType = AuthenticationTypes.NTML;
			RequestNewRow.UseAuthentication = True;
			Return;
		EndIf;
	EndIf;
	
	SearchedTitle = "authorization";
	AuthenticationHeaderValue = "";
	
	For Each Str In RequestNewRow.Headers Do
		If Lower(Str.Key)	= SearchedTitle Then
			AuthenticationHeaderValue = Str.Value;
			Break;
		EndIf;	
	EndDo;
	
	If Not ValueIsFilled(AuthenticationHeaderValue) Then
		Return;
	EndIf;
	
	RowsValuesHeader = StrSplit(AuthenticationHeaderValue, " ");
	If RowsValuesHeader.Count() < 2 Then
		Return;
	EndIf;
	
	Scheme = RowsValuesHeader[0];
	If Lower(Scheme) = "basic" Then
		RequestNewRow.AuthenticationType = AuthenticationTypes.Basic;
		RequestNewRow.UseAuthentication = True;
		
		//@skip-check empty-except-statement
		Try
			UserString = GetStringFromBinaryData(Base64Value(RowsValuesHeader[1]));
		Except
		EndTry;
	
		UserNameRowArray = StrSplit(UserString, ":");
		RequestNewRow.AuthenticationUser = UserNameRowArray[0];
		
		If UserNameRowArray.Count() > 1 Then
			UserNameRowArray.Delete(0);
			RequestNewRow.AuthenticationPassword = StrConcat(UserNameRowArray,":");
		EndIf;
	ElsIf Lower(Scheme) = "bearer" Then 
		RequestNewRow.AuthenticationType = AuthenticationTypes.BearerToken;
		RequestNewRow.UseAuthentication = True;
		RequestNewRow.AuthenticationPassword = RowsValuesHeader[1];
	EndIf;
EndProcedure

// Edit request body in JSON editor.
// 
// Parameters:
//  Result - Строка, Undefined- Result
//  AdditionalParameters - Structure:
//  * CurrentRow - Number, Undefined -
&AtClient
Procedure EditRequestBodyInJSONEditorFinish(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;

	If AdditionalParameters.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	TreeRow = RequestsTree.FindByID(AdditionalParameters.CurrentRow);
	If TreeRow = Undefined Then
		Return;
	EndIf;

	TreeRow.BodyString = Result;
	
	//FillJSONStructureInRequestsTree();
EndProcedure


&AtServer
Function GeneratedHTTPRequestInitializationConnection(RequestsTreeRow, StructureURL)
	If RequestsTreeRow.UseProxy Then
		ProxySettingsText = StrTemplate("ProxyProtocol = %1;
										 |ProxyServer = %2;
										 |ProxyPort = %3;
										 |ProxyUser = %4;
										 |ProxyPassword = %5;
										 |ProxyOSAuthentication = %6;
										 |
										 |ProxySettings = New InternetProxy(True);
										 |ProxySettings.Set(ProxyProtocol,
										 |					ProxyServer,
										 |					ProxyPort,
										 |					ProxyUser,
										 |					ProxyPassword,
										 |					ProxyOSAuthentication);",
										 UT_CodeGenerator.StringInCodeString(StructureURL.Scheme),
										 UT_CodeGenerator.StringInCodeString(RequestsTreeRow.ProxyServer),
										 UT_CodeGenerator.NumberInCodeString(RequestsTreeRow.ProxyPort),
										 UT_CodeGenerator.StringInCodeString(RequestsTreeRow.ProxyUser),
										 UT_CodeGenerator.StringInCodeString(RequestsTreeRow.ProxyPassword),
										 UT_CodeGenerator.BooleanInCodeString(RequestsTreeRow.ProxyOSAuthentication));
	Else
		ProxySettingsText = "ProxySettings = " + UT_CodeGenerator.UndefinedInCodeString() + ";";
	EndIf;	
	
	Port = UT_CodeGenerator.UndefinedInCodeString();
	If ValueIsFilled(StructureURL.Port) Then
		Port = UT_CodeGenerator.NumberInCodeString(StructureURL.Port);
	EndIf;	
		
	UseNTMAuthentication = Undefined;
	If UT_CommonClientServer.PlatformVersionNotLess("8.3.7") Then
		If RequestsTreeRow.UseAuthentication
			 И RequestsTreeRow.AuthenticationType = AuthenticationTypes().NTML Then
			UseNTMAuthentication = True;
		EndIf;
	EndIf;

	SecuredConnection = UT_CodeGenerator.UndefinedInCodeString();
	If Lower(StructureURL.Scheme) = "https" Then
		SecuredConnection = "New OpenSSLSecureConnection";
	EndIf;
	
	If UseNTMAuthentication = Undefined Then
		UseNTMAuthenticationForCode = UT_CodeGenerator.UndefinedInCodeString();
		HTTPConnection = "New HTTPConnection(Server, Port, , ProxySettings, Timeout, SecuredConnection)";
	Else
		UseNTMAuthenticationForCode = UT_CodeGenerator.BooleanInCodeString(UseNTMAuthentication);
		HTTPConnection = "New HTTPConnection(Server, Port, , ProxySettings, Timeout, SecuredConnection, UseNTMAuthentication)";
	EndIf;

	HTTPConnectionsInitializationText = StrTemplate("
												|Server = %1;
												|Port = %2;
												|UseNTMAuthentication = %3;
												|SecuredConnection = %4;
												|Timeout = %5;
												|
												|HTTPConnection = %6;",
												UT_CodeGenerator.StringInCodeString(StructureURL.Host),
												Port,
												UseNTMAuthenticationForCode,
												SecuredConnection,
												UT_CodeGenerator.NumberInCodeString(RequestsTreeRow.Timeout),
												HTTPConnection);
	
	Return ProxySettingsText + HTTPConnectionsInitializationText;
EndFunction

&AtServer
Function GeneratedHTTPRequestInitializationCode(RequestsTreeRow, StructureURL)
	RowsToConcatenate = New Array;
	
	RowsToConcatenate.Add(StrTemplate("NewRequest = New HTTPRequest;
											|NewRequest.ResourceAddress = %1;
											|", UT_CodeGenerator.StringInCodeString(StructureURL.Path)));
	
	
	
	For Each HeaderRow In RequestsTreeRow.Headers Do
		If Not HeaderRow.Using Then
			Continue;
		EndIf;

		RowsToConcatenate.Add(StrTemplate("NewRequest.Headers.Insert(%1,%2);",
												UT_CodeGenerator.StringInCodeString(HeaderRow.Key),
												UT_CodeGenerator.StringInCodeString(HeaderRow.Value)));
	EndDo;

	AuthenticationTypes = AuthenticationTypes();
	If RequestsTreeRow.UseAuthentication
		 And ValueIsFilled(RequestsTreeRow.AuthenticationType)
		 And RequestsTreeRow.AuthenticationType <> AuthenticationTypes.None Then

		If RequestsTreeRow.AuthenticationType = AuthenticationTypes.Basic Then
			RowsToConcatenate.Add(StrTemplate("
													|// Authentication Basic
													|AuthenticationUser = %1;
													|AuthenticationPassword = %2;
													|NewRequest.Headers.Insert(""Authorization"", ""Basic ""+Base64Строка(GetBinaryDataFromString(AuthenticationUser + "":""+ AuthenticationPassword)));",
													UT_CodeGenerator.StringInCodeString(RequestsTreeRow.AuthenticationUser),
													UT_CodeGenerator.StringInCodeString(RequestsTreeRow.AuthenticationPassword)));

		ElsIf RequestsTreeRow.AuthenticationType = AuthenticationTypes.BearerToken Then

			Prefix = TrimAll(RequestsTreeRow.AuthenticationTokenPrefix);
			If Not ValueIsFilled(Prefix) Then
				Prefix = "Bearer";
			EndIf;
			RowsToConcatenate.Add(StrTemplate("
										|// Authentication BearerToken
										|Token = %1;
										|TokenPrefix = %2;
										|NewRequest.Headers.Insert(""Authorization"", TokenPrefix +"" ""+Token);",
										UT_CodeGenerator.StringInCodeString(RequestsTreeRow.AuthenticationPassword),
										UT_CodeGenerator.StringInCodeString(Prefix)));
		EndIf;

	EndIf;

	RowsToConcatenate.Add("
	|// Body request");
	If RequestsTreeRow.BodyType = TypesOfRequestBody.Bodyless Then
		RowsToConcatenate.Add("// Bodyless");
	ElsIf RequestsTreeRow.BodyType = TypesOfRequestBody.String Then
		If RequestsTreeRow.UseBOM = 0 Then
			BOM = "ByteOrderMarkUse.Auto";
		ElsIf (RequestsTreeRow.UseBOM = 1) Then
			BOM = "ByteOrderMarkUse.Use";
		Else
			BOM = "ByteOrderMarkUse.DontUse";
		EndIf;

		RowsToConcatenate.Add(StrTemplate("// Body String
										|RequestBody = %1;
										|UsingBOM = %2;",
										UT_CodeGenerator.StringInCodeString(RequestsTreeRow.BodyString),
												BOM));

		If RequestsTreeRow.BodyEncoding = "Auto" Then
			RowsToConcatenate.Add("NewRequest.SetBodyFromString(RequestBody, , UsingBOM);");
		Else
			Try
				//@skip-check module-unused-local-variable
				BodyEncoding = TextEncoding[RequestsTreeRow.BodyEncoding];
				RowsToConcatenate.Add(StrTemplate("BodyEncoding = TextEncoding.%1;",
														RequestsTreeRow.BodyEncoding));
			Except
				RowsToConcatenate.Add(StrTemplate("BodyEncoding = %1;",
														UT_CodeGenerator.StringInCodeString(RequestsTreeRow.BodyEncoding)));

			EndTry;
			RowsToConcatenate.Add("NewRequest.SetBodyFromString(RequestBody, BodyEncoding, UsingBOM);");

		EndIf;
	ElsIf RequestsTreeRow.BodyType = TypesOfRequestBody.BinaryData Then
		If RequestsTreeRow.ТелоBinaryData <> Undefined Then
			BodyBinaryData = UT_Common.ValueFromBinaryDataContainerStorage(RequestsTreeRow.BodyBinaryData);
			If TypeOf(BodyBinaryData) = Type("BinaryData") Then
				BinaryDataString = Base64Строка(BodyBinaryData);
				RowsToConcatenate.Add(StrTemplate("// Body BinaryData
												|RequestBody = Base64Value(%1);
												|NewRequest.SetBodyFromBinaryData(RequestBody);",
												UT_CodeGenerator.StringInCodeString(BinaryDataString)));

			EndIf;
		EndIf;
	ElsIf RequestsTreeRow.BodyType = TypesOfRequestBody.File Then
		RowsToConcatenate.Add(StrTemplate("// File body
										|RequestBody = %1;
										|NewRequest.SetBodyFileName(RequestBody);",
										UT_CodeGenerator.StringInCodeString(RequestsTreeRow.BodyFileName)));
	ElsIf RequestsTreeRow.BodyType = TypesOfRequestBody.MultypartForm Then 
		MultypartItemsType = MultypartItemsType();
		
		RowsToConcatenate.Add("// Body Multypartdata
		|MultipartBodySplitter = ""---""+StrReplace(String(New UUID), ""-"", """")+""---"";
		|
		|FilesToCombine = New Array;");	

		FilesExist = False;
		For RowIndex = 0 To RequestsTreeRow.MultipartBody.Count() - 1 Do
			MultypartItemRow = RequestsTreeRow.MultipartBody[RowIndex];
			If Not MultypartItemRow.Using Then
				Continue;
			EndIf;
			
			If MultypartItemRow.Type = MultypartItemsType.String Then
				FilesExist = True;

				RowsToConcatenate.Add(StrTemplate("
												|CurrentParameterName = %1;
												|CurrentParameterValue = %2;
												|
												|StreamRecord = New MemoryStream;
												|
												|InputFile = New TextWriter(StreamRecord, TextEncoding.ANSI, Chars.LF);
												|InputFile.WriteLine("""");
												|InputFile.WriteLine(""--"" + MultipartBodySplitter);
												|InputFile.WriteLine(""Content-Disposition: form-data;name=""""""+CurrentParameterName+"""""""");
												|InputFile.WriteLine("""");
												|InputFile.Close();
												|FilesToCombine.Add(StreamRecord.CloseAndGetBinaryData());
												|
												|FilesToCombine.Add(GetBinaryDataFromString(CurrentParameterValue));",
												UT_CodeGenerator.StringInCodeString(MultypartItemRow.Name),
												UT_CodeGenerator.StringInCodeString(MultypartItemRow.Value)));

			ElsIf MultypartItemRow.Type = MultypartItemsType.File Then
				If Not ValueIsFilled(MultypartItemRow.Value) Then
					Continue;
				EndIf;

				FilesExist = True;

				RowsToConcatenate.Add(StrTemplate("
												|CurrentParameterName = %1;
												|CurrentFileName = %2;
												|
												|File = New File(CurrentFileName);
												|FileBinaryData = New BinaryData(CurrentFileName);
												|
												|StreamRecord = New MemoryStream;
												|
												|InputFile = New TextWriter(StreamRecord, TextEncoding.ANSI, Chars.LF);
												|InputFile.WriteLine("""");
												|InputFile.WriteLine(""--"" + MultipartBodySplitter);
												|InputFile.WriteLine(""Content-Disposition: form-data;name=""""""
												|													+ CurrentParameterName 
												|													+ """""";filename="""""" 
												|													+ File.Name+ """""""");
												|InputFile.WriteLine(""Content-Type: application/octet-stream"");  
												|InputFile.WriteLine("""");
												|InputFile.Close();
												|FilesToCombine.Add(StreamRecord.CloseAndGetBinaryData());
												|
												|FilesToCombine.Add(FileBinaryData);",
												UT_CodeGenerator.StringInCodeString(MultypartItemRow.Name),
												UT_CodeGenerator.StringInCodeString(MultypartItemRow.Value)));
			EndIf;

		EndDo;
		
		If FilesExist Then
			RowsToConcatenate.Add("
			|StreamRecord = New MemoryStream;
			|InputFile = New TextWriter(StreamRecord, TextEncoding.ANSI, Chars.LF);
			|InputFile.WriteLine("""");
			|InputFile.WriteLine(""--"" + MultipartBodySplitter + ""--"");
			|InputFile.Close();
			|
			|FilesToCombine.Add(StreamRecord.CloseAndGetBinaryData());
			|
			|FinalBD = ConcatBinaryData(FilesToCombine);
			|
			|NewRequest.SetBodyFromBinaryData(FinalBD);
			|
			|NewRequest.Headers.Insert(""Content-Type"", ""multipart/form-data; boundary=""+MultipartBodySplitter);
			|NewRequest.Headers.Insert(""Content-Length"", XMLString(FinalBD.Size()));
			|");
		EndIf;

	EndIf;

	Return StrConcat(RowsToConcatenate, Chars.LF);
	

	
EndFunction

&AtServer
Function GeneratedRequestExecutionCode(RequestsTreeRow)
	
	
	Return StrTemplate("RequestType = %1;
					  |
					  |StartExecution = CurrentUniversalDateInMilliseconds();
					  |
					  |HTTPResponse = HTTPConnection.CallHTTPMethod(RequestType, NewRequest);
					  |FinishExecution = CurrentUniversalDateInMilliseconds();
					  |
					  |Duration = FinishExecution - StartExecution;
					  |
					  |StatusCode = HTTPResponse.StatusCode;
					  |ResponseBodyString = HTTPResponse.GetBodyAsString();
					  |ResponseBodyBinaryData = HTTPResponse.GetBodyAsBinaryData();
					  |", UT_CodeGenerator.StringInCodeString(RequestsTreeRow.HTTPRequest));
EndFunction

Function GeneratedExecutionCodeAtServer(RowID)
	RequestsTreeRow = RequestsTree.FindByID(RowID);
	StructureURL = UT_HTTPConnector.ParseURL(RequestsTreeRow.RequestURL);
	
	
	ExecuteText = UT_CodeGenerator.StandardGeneratedCodeHeader("HTTP Request Console",
															RequestsFileName,
															RequestsTreeRow.Name);

	ExecuteText = ExecuteText
					  + GeneratedHTTPRequestInitializationConnection(RequestsTreeRow, StructureURL)
					  + Chars.LF
					  + GeneratedHTTPRequestInitializationCode(RequestsTreeRow, StructureURL)
					  + Chars.LF
					  + GeneratedRequestExecutionCode(RequestsTreeRow);
								
	Return ExecuteText;
EndFunction



#EndRegion

