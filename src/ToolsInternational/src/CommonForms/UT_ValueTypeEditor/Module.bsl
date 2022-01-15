#Область СобытияФормы

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	РежимРаботы=Параметры.РежимЗапуска;
	
	DataType=Параметры.DataType;
	Если ТипЗнч(DataType)=Тип("ОписаниеТипов") Тогда
		НачальныйТипДанных=DataType;
	Иначе
		НачальныйТипДанных=Новый ОписаниеТипов;
	КонецЕсли;
	
	ЗаполнитьДанныеКвалификаторовПоПервоначальномуТипуДанных();
	
	ЗаполнитьДеревоТипов(Истина);
	
	УстановитьУсловноеОформление();
КонецПроцедуры

#КонецОбласти

#Область СобытияЭлементовФормы

&НаКлиенте
Процедура ДеревоТиповПриАктивизацииСтроки(Элемент)
	ТекДанные=Элементы.ДеревоТипов.ТекущиеДанные;
	Если ТекДанные=Неопределено Тогда
		Возврат;
	КонецЕсли;
	
	Элементы.ГруппаКвалификаторЧисла.Видимость=ТекДанные.Имя="Число";
	Элементы.ГруппаКвалификаторСтроки.Видимость=ТекДанные.Имя="Строка";
	Элементы.ГруппаКвалификаторДаты.Видимость=ТекДанные.Имя="Дата";
	
КонецПроцедуры

&НаКлиенте
Процедура НеограниченнаяДлинаСтрокиПриИзменении(Элемент)
	Если НеограниченнаяДлинаСтроки Тогда
		ДлинаСтроки=0;
		ДопустамаяДлинаСтрокиФиксированная=Ложь;
	КонецЕсли;
	Элементы.ДопустамаяДлинаСтрокиФиксированная.Доступность=Не НеограниченнаяДлинаСтроки;
КонецПроцедуры

&НаКлиенте
Процедура ДлинаСтрокиПриИзменении(Элемент)
	Если Не ЗначениеЗаполнено(ДлинаСтроки) Тогда
		НеограниченнаяДлинаСтроки=Истина;
		ДопустамаяДлинаСтрокиФиксированная=Ложь;
	Иначе
		НеограниченнаяДлинаСтроки=Ложь;
	КонецЕсли;
	Элементы.ДопустамаяДлинаСтрокиФиксированная.Доступность=Не НеограниченнаяДлинаСтроки;
КонецПроцедуры

&НаКлиенте
Процедура СтрокаПоискаПриИзменении(Элемент)
	ЗаполнитьДеревоТипов();
	РазвернутьЭлементыДерева();
КонецПроцедуры

&НаКлиенте
Процедура ДеревоТиповВыбранПриИзменении(Элемент)
	ТекСтрока=Элементы.ДеревоТипов.ТекущиеДанные;
	Если ТекСтрока=Неопределено Тогда
		Возврат;
	КонецЕсли;
	
	Если ТекСтрока.Выбран Тогда
		Если Не СоставнойТип Тогда
			ВыбранныеТипы.Очистить();
		ИначеЕсли ТекСтрока.НедоступенДляСоставногоТипа Тогда
			Если ВыбранныеТипы.Количество()>0 Тогда
				ПоказатьВопрос(Новый ОписаниеОповещения("ДеревоТиповВыбранПриИзмененииЗавершение", ЭтаФорма, Новый Структура("ТекСтрока",ТекСтрока)), "Выбран тип, который не может быть включен в составной тип данных.
				|Будут исключены остальные типы данных.
				|Продолжить?",РежимДиалогаВопрос.ДаНет);
	        	Возврат;
			КонецЕсли;
		Иначе
			ЕстьНедоступныйДляСоставногоТипа=Ложь;
			Для Каждого Эл Из ВыбранныеТипы Цикл
				Если Эл.Пометка Тогда
					ЕстьНедоступныйДляСоставногоТипа=Истина;
					Прервать;
				КонецЕсли;
			КонецЦикла;
			
			Если ЕстьНедоступныйДляСоставногоТипа Тогда
				ПоказатьВопрос(Новый ОписаниеОповещения("ДеревоТиповВыбранПриИзмененииЗавершениеБылЗапрещенныйДляСоставногоТип", ЭтаФорма, Новый Структура("ТекСтрока",ТекСтрока)), "Ранее был выбран тип, который не может быть 
				|включен в составной тип данных и будет исключен.
				|Продолжить?",РежимДиалогаВопрос.ДаНет);
				Возврат;
			КонецЕсли;
		КонецЕсли;
	Иначе
		Элемент=ВыбранныеТипы.НайтиПоЗначению(ТекСтрока.Имя);
		Если Элемент<>Неопределено Тогда
			ВыбранныеТипы.Удалить(Элемент);
		КонецЕсли;
		
	КонецЕсли;
	ДеревоТиповВыбранПриИзмененииФрагмент(ТекСтрока);

	
КонецПроцедуры

&НаКлиенте
Процедура СоставнойТипПриИзменении(Элемент)
	Если Не СоставнойТип Тогда
		Если ВыбранныеТипы.Количество()=0 Тогда
			ДобавитьВыбранныйТип("Строка");
		КонецЕсли;
		Тип=ВыбранныеТипы[ВыбранныеТипы.Количество()-1];
		ВыбранныеТипы.Очистить();
		ДобавитьВыбранныйТип(Тип);
		
		УстановитьВыбранныеТипыВДереве(ДеревоТипов,ВыбранныеТипы);
	КонецЕсли;
КонецПроцедуры

#КонецОбласти

#Область ОбработчикиКомандФормы

&НаКлиенте
Процедура Применить(Команда)
	МассивТипов=МассивВыбранныхТипов();
	
	ТипыСтрокой=Новый Массив;
	ТипыТипом=Новый Массив;
	
	Для Каждого Тип ИЗ МассивТипов Цикл
		Если ТипЗнч(Тип) = Тип("Тип") Тогда
			ТипыТипом.Добавить(Тип);
		Иначе
			ТипыСтрокой.Добавить(Тип);
		КонецЕсли;
	КонецЦикла;
	
	Если НеотрицательноеЧисло Тогда
		Знак=ДопустимыйЗнак.Неотрицательный;
	Иначе
		Знак=ДопустимыйЗнак.Любой;
	КонецЕсли;
		
	КвалификаторЧисла=Новый КвалификаторыЧисла(ДлинаЧисла,ТочностьЧисла,Знак);
	КвалификаторСтроки=Новый КвалификаторыСтроки(ДлинаСтроки, ?(ДопустамаяДлинаСтрокиФиксированная,ДопустимаяДлина.Фиксированная, ДопустимаяДлина.Переменная));
	
	Если СоставДаты=1 Тогда
		ЧастьДаты=ЧастиДаты.Время;
	ИначеЕсли СоставДаты=2 Тогда
		ЧастьДаты=ЧастиДаты.ДатаВремя;
	Иначе
		ЧастьДаты=ЧастиДаты.Дата;
	КонецЕсли;
	
	КвалификаторДаты=Новый КвалификаторыДаты(ЧастьДаты);
	
	Описание=Новый ОписаниеТипов;
	Если ТипыТипом.Количество()>0 Тогда 
		Описание=Новый ОписаниеТипов(Описание, ТипыТипом,,КвалификаторЧисла,КвалификаторСтроки,КвалификаторДаты);
	КонецЕсли;
	Если ТипыСтрокой.Количество()>0 Тогда 
		Описание=Новый ОписаниеТипов(Описание, СтрСоединить(ТипыСтрокой,","),,КвалификаторЧисла,КвалификаторСтроки,КвалификаторДаты);
	КонецЕсли;
	
	Закрыть(Описание);
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

&НаСервере
Функция ДоступноХранилищеЗначений()
	Возврат Истина;	
КонецФункции
&НаСервере
Функция ДоступноNull()
	Возврат РежимРаботы<>0;	
КонецФункции
&НаСервере
Функция ТипыДляЗапроса()
	Возврат РежимРаботы=1;	
КонецФункции

&НаСервере
Функция ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,ИмяТипа, Картинка, Представление = "", СтрокаДерева = Неопределено, ЭтоГруппа = Ложь, Групповой=Ложь, НедоступенДляСоставногоТипа=Ложь)
	
	Если ЗначениеЗаполнено(Представление) Тогда
		ПредставлениеТипа=Представление;
	Иначе
		ПредставлениеТипа=ИмяТипа;
	КонецЕсли;

	Если ЗначениеЗаполнено(СтрокаПоиска) и Не Групповой Тогда
		Если СтрНайти(НРег(ПредставлениеТипа), НРег(СтрокаПоиска))=0 Тогда
			Возврат Неопределено;
		КонецЕсли;
	КонецЕсли;
	
	Если СтрокаДерева = Неопределено Тогда
		ЭлементДобавления=ДеревоТипов;
	Иначе
		ЭлементДобавления=СтрокаДерева;
	КонецЕсли;

	НоваяСтрока=ЭлементДобавления.ПолучитьЭлементы().Добавить();
	НоваяСтрока.Имя=ИмяТипа;
	НоваяСтрока.Представление=ПредставлениеТипа;
	НоваяСтрока.Картинка=Картинка;
	НоваяСтрока.ЭтоГруппа=ЭтоГруппа;
	НоваяСтрока.НедоступенДляСоставногоТипа=НедоступенДляСоставногоТипа;
	
	Если ЗаполнятьВыбранныеТипы Тогда
		Попытка
			ТекТип=Тип(ИмяТипа);
		Исключение
			ТекТип=Неопределено;
		КонецПопытки;
		Если ТекТип<>Неопределено Тогда
			Если НачальныйТипДанных.СодержитТип(ТекТип) Тогда
				ВыбранныеТипы.Добавить(НоваяСтрока.Имя,,НоваяСтрока.НедоступенДляСоставногоТипа);
			КонецЕсли;
		КонецЕсли;
	КонецЕсли;

	
	Возврат НоваяСтрока;
КонецФункции

&НаСервере
Процедура ЗаполнитьТипыПоВидуОбъекта(ВидОбъектовМетаданных, ПрефиксТипа, Картинка,ЗаполнятьВыбранныеТипы)
	КоллекцияОбъектов=Метаданные[ВидОбъектовМетаданных];
	
	СтрокаКоллекции=ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,ПрефиксТипа,Картинка,ПрефиксТипа,,,Истина);
	
	Для Каждого ОбъектМетаданных Из КоллекцияОбъектов Цикл
		ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,ПрефиксТипа+"."+ОбъектМетаданных.Имя, Картинка,ОбъектМетаданных.Имя,СтрокаКоллекции);
	КонецЦикла;
	
	УдалитьСтрокуДереваЕслиНетПодчиненныхПриПоиске(СтрокаКоллекции);
КонецПроцедуры

&НаСервере
Процедура ЗаполнитьПримитивныеТипы(ЗаполнятьВыбранныеТипы)
	//ДобавитьТипВДеревоТипов("Произвольный", БиблиотекаКартинок.УИ_ПроизвольныйТип);
	ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"Число", БиблиотекаКартинок.UT_Number);
	ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"Строка", БиблиотекаКартинок.UT_String);
	ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"Дата", БиблиотекаКартинок.UT_Date);
	ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"Булево", БиблиотекаКартинок.UT_Boolean);
	Если ДоступноХранилищеЗначений() Тогда      
		ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"ХранилищеЗначения", Новый Картинка);
	КонецЕсли;
	Если ТипыДляЗапроса() Тогда
		ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"ТаблицаЗначений", БиблиотекаКартинок.UT_ValueTable);
		ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"СписокЗначений", БиблиотекаКартинок.UT_ValueList);
		ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"Массив", БиблиотекаКартинок.UT_Array);
		ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"Тип", БиблиотекаКартинок.ВыбратьТип);
		ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"МоментВремени", БиблиотекаКартинок.UT_PointInTime);
		ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"Граница", БиблиотекаКартинок.UT_Boundary);
	КонецЕсли;
	
	ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"УникальныйИдентификатор", БиблиотекаКартинок.UT_UUID);
	Если ДоступноNull() Тогда
		ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"Null", БиблиотекаКартинок.UT_Null);
	КонецЕсли;
КонецПроцедуры

&НаСервере
Процедура ЗаполнитьТипыХарактеристик(ЗаполнятьВыбранныеТипы)
	//Характеристики
	ПланыВидов=Метаданные.ПланыВидовХарактеристик;
	Если ПланыВидов.Количество()=0 Тогда
		Возврат;
	КонецЕсли;
	
	СтрокаХарактеристик=ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"Характеристики", БиблиотекаКартинок.Папка,,,Истина,Истина);
	
	Для Каждого План Из ПланыВидов Цикл
		ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"Характеристика."+План.Имя,Новый Картинка,План.Имя,СтрокаХарактеристик,,,Истина);
	КонецЦикла;
	
	УдалитьСтрокуДереваЕслиНетПодчиненныхПриПоиске(СтрокаХарактеристик);

КонецПроцедуры

&НаСервере
Процедура ЗаполнитьОпределяемыеТипы(ЗаполнятьВыбранныеТипы)
	//Характеристики
	Типы=Метаданные.ОпределяемыеТипы;
	Если Типы.Количество()=0 Тогда
		Возврат;
	КонецЕсли;
	
	СтрокаТипа=ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"ОпределяемыйТип", БиблиотекаКартинок.Папка,,,Истина, Истина);
	
	Для Каждого ОпределяемыйТип Из Типы Цикл
		ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"ОпределяемыйТип."+ОпределяемыйТип.Имя,Новый Картинка,ОпределяемыйТип.Имя,СтрокаТипа,,,Истина);
	КонецЦикла;
	УдалитьСтрокуДереваЕслиНетПодчиненныхПриПоиске(СтрокаТипа);
КонецПроцедуры

&НаСервере
Процедура ЗаполнитьТипыСистемныеПеречисления(ЗаполнятьВыбранныеТипы)
	СтрокаТипа=ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"СистемныеПеречисления", БиблиотекаКартинок.Папка,"Системные перечисления",,Истина, Истина);

	ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"ВидДвиженияНакопления",БиблиотекаКартинок.UT_AccumulationRecordType,,СтрокаТипа);
	ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"ВидСчета",БиблиотекаКартинок.ПланСчетовОбъект,,СтрокаТипа);
	ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"ВидДвиженияБухгалтерии",БиблиотекаКартинок.ПланСчетов,,СтрокаТипа);
	ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"ИспользованиеАгрегатаРегистраНакопления",Новый Картинка,,СтрокаТипа);
	ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"ПериодичностьАгрегатаРегистраНакопления",Новый Картинка,,СтрокаТипа);
	
	УдалитьСтрокуДереваЕслиНетПодчиненныхПриПоиске(СтрокаТипа);
КонецПроцедуры

&НаСервере
Процедура ЗаполнитьДеревоТипов(ЗаполнятьВыбранныеТипы=Ложь)
	ДеревоТипов.ПолучитьЭлементы().Очистить();
	ЗаполнитьПримитивныеТипы(ЗаполнятьВыбранныеТипы);
	ЗаполнитьТипыПоВидуОбъекта("Справочники", "СправочникСсылка",БиблиотекаКартинок.Справочник,ЗаполнятьВыбранныеТипы);
	ЗаполнитьТипыПоВидуОбъекта("Документы", "ДокументСсылка",БиблиотекаКартинок.Документ,ЗаполнятьВыбранныеТипы);
	ЗаполнитьТипыПоВидуОбъекта("ПланыВидовХарактеристик", "ПланВидовХарактеристикСсылка", БиблиотекаКартинок.ПланВидовХарактеристик,ЗаполнятьВыбранныеТипы);
	ЗаполнитьТипыПоВидуОбъекта("ПланыСчетов", "ПланСчетовСсылка", БиблиотекаКартинок.ПланСчетов,ЗаполнятьВыбранныеТипы);
	ЗаполнитьТипыПоВидуОбъекта("ПланыВидовРасчета", "ПланВидовРасчетаСсылка", БиблиотекаКартинок.ПланВидовРасчета,ЗаполнятьВыбранныеТипы);
	ЗаполнитьТипыПоВидуОбъекта("ПланыОбмена", "ПланОбменаСсылка", БиблиотекаКартинок.ПланОбмена,ЗаполнятьВыбранныеТипы);
	ЗаполнитьТипыПоВидуОбъекта("Перечисления", "ПеречислениеСсылка", БиблиотекаКартинок.Перечисление,ЗаполнятьВыбранныеТипы);
	ЗаполнитьТипыПоВидуОбъекта("БизнесПроцессы", "БизнесПроцессСсылка", БиблиотекаКартинок.БизнесПроцесс,ЗаполнятьВыбранныеТипы);
	ЗаполнитьТипыПоВидуОбъекта("Задачи", "ЗадачаСсылка", БиблиотекаКартинок.Задача,ЗаполнятьВыбранныеТипы);
	//ЗаполнитьТипыПоВидуОбъекта("ТочкиМаршрутаБизнесПроцессаСсылка", "ТочкаМаршрутаБизнесПроцессаСсылка");
	
	ЗаполнитьТипыХарактеристик(ЗаполнятьВыбранныеТипы);
	Попытка
		ЗаполнитьОпределяемыеТипы(ЗаполнятьВыбранныеТипы);
	Исключение
	КонецПопытки;
	ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"ЛюбаяСсылка", Новый Картинка, "Любая ссылка");

	
	Если РежимРаботы=3 Тогда
		ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"СтандартнаяДатаНачала", Новый Картинка, "Стандартный дата начала");
		ДобавитьТипВДеревоТипов(ЗаполнятьВыбранныеТипы,"СтандартныйПериод", Новый Картинка, "Стандартный период");
		ЗаполнитьТипыСистемныеПеречисления(ЗаполнятьВыбранныеТипы);
	КонецЕсли;
	
	УстановитьВыбранныеТипыВДереве(ДеревоТипов,ВыбранныеТипы);
КонецПроцедуры

&НаСервере
Процедура УстановитьУсловноеОформление()
	// Группы нелья выбирать
	НовоеУО=УсловноеОформление.Элементы.Добавить();
	НовоеУО.Использование=Истина;
	UT_CommonClientServer.SetFilterItem(НовоеУО.Отбор,
		"Элементы.ДеревоТипов.ТекущиеДанные.ЭтоГруппа", Истина);
	Поле=НовоеУО.Поля.Элементы.Добавить();
	Поле.Использование=Истина;
	Поле.Поле=Новый ПолеКомпоновкиДанных("ДеревоТиповВыбран");

	Оформление=НовоеУО.Оформление.НайтиЗначениеПараметра(Новый ПараметрКомпоновкиДанных("Отображать"));
	Оформление.Использование=Истина;
	Оформление.Значение=Ложь;
	
	// Если строка неограниченная то нельзя менять допустимую длину строки
	НовоеУО=УсловноеОформление.Элементы.Добавить();
	НовоеУО.Использование=Истина;
	UT_CommonClientServer.SetFilterItem(НовоеУО.Отбор,
		"ДлинаСтроки", 0);
	Поле=НовоеУО.Поля.Элементы.Добавить();
	Поле.Использование=Истина;
	Поле.Поле=Новый ПолеКомпоновкиДанных("ДопустамаяДлинаСтрокиФиксированная");

	Оформление=НовоеУО.Оформление.НайтиЗначениеПараметра(Новый ПараметрКомпоновкиДанных("ТолькоПросмотр"));
	Оформление.Использование=Истина;
	Оформление.Значение=Истина;
	
	
КонецПроцедуры

&НаСервере
Процедура УдалитьСтрокуДереваЕслиНетПодчиненныхПриПоиске(СтрокаДерева)
	Если Не ЗначениеЗаполнено(СтрокаПоиска) Тогда
		Возврат;
	КонецЕсли;
	Если СтрокаДерева.ПолучитьЭлементы().Количество()=0 Тогда
		ДеревоТипов.ПолучитьЭлементы().Удалить(СтрокаДерева);
	КонецЕсли;
КонецПроцедуры

&НаКлиенте
Процедура РазвернутьЭлементыДерева()
	Для каждого СтрокаДерева Из ДеревоТипов.ПолучитьЭлементы() Цикл 
		Элементы.ДеревоТипов.Развернуть(СтрокаДерева.ПолучитьИдентификатор());
	КонецЦикла;
КонецПроцедуры

&НаКлиентеНаСервереБезКонтекста
Процедура УстановитьВыбранныеТипыВДереве(СтрокаДерева,ВыбранныеТипы)
	Для Каждого Стр ИЗ СтрокаДерева.ПолучитьЭлементы() Цикл
		Стр.Выбран=ВыбранныеТипы.НайтиПоЗначению(Стр.Имя)<>Неопределено;
		
		УстановитьВыбранныеТипыВДереве(Стр, ВыбранныеТипы);
	КонецЦикла;
КонецПроцедуры

&НаКлиенте
Процедура ДобавитьВыбранныйТип(СтрокаДереваИлиТип)
	Если ТипЗнч(СтрокаДереваИлиТип)=Тип("Строка") Тогда
		ИмяТипа=СтрокаДереваИлиТип;
		НедоступенДляСоставногоТипа=Ложь;
	ИначеЕсли ТипЗнч(СтрокаДереваИлиТип)=Тип("ЭлементСпискаЗначений") Тогда
		ИмяТипа=СтрокаДереваИлиТип.Значение;
		НедоступенДляСоставногоТипа=СтрокаДереваИлиТип.Пометка;
	Иначе
		ИмяТипа=СтрокаДереваИлиТип.Имя;
		НедоступенДляСоставногоТипа=СтрокаДереваИлиТип.НедоступенДляСоставногоТипа;
	КонецЕсли;
	
	Если ВыбранныеТипы.НайтиПоЗначению(ИмяТипа)=Неопределено Тогда
		ВыбранныеТипы.Добавить(ИмяТипа,,НедоступенДляСоставногоТипа);
	КонецЕсли;
КонецПроцедуры
&НаКлиенте
Процедура ДеревоТиповВыбранПриИзмененииЗавершение(РезультатВопроса, ДополнительныеПараметры) Экспорт
	
	Ответ=РезультатВопроса;
	
	Если Ответ=КодВозвратаДиалога.Нет Тогда
		ДополнительныеПараметры.ТекСтрока.Выбран=Ложь;
		Возврат;
	КОнецЕсли;

	ВыбранныеТипы.Очистить();
	ДеревоТиповВыбранПриИзмененииФрагмент(ДополнительныеПараметры.ТекСтрока);
КонецПроцедуры
&НаКлиенте
Процедура ДеревоТиповВыбранПриИзмененииЗавершениеБылЗапрещенныйДляСоставногоТип(РезультатВопроса, ДополнительныеПараметры) Экспорт
	
	Ответ=РезультатВопроса;
	
	Если Ответ=КодВозвратаДиалога.Нет Тогда
		ДополнительныеПараметры.ТекСтрока.Выбран=Ложь;
		Возврат;
	КОнецЕсли;

	МассивУдаляемыхЭлементов=Новый Массив;
	Для Каждого Эл Из ВыбранныеТипы Цикл 
		Если Эл.Пометка Тогда
			МассивУдаляемыхЭлементов.Добавить(Эл);
		КонецЕсли;
	КонецЦикла;
	
	Для Каждого Эл Из  МассивУдаляемыхЭлементов Цикл
		ВыбранныеТипы.Удалить(Эл);
	КонецЦикла;
	
	ДеревоТиповВыбранПриИзмененииФрагмент(ДополнительныеПараметры.ТекСтрока);
КонецПроцедуры

&НаКлиенте
Процедура ДеревоТиповВыбранПриИзмененииФрагмент(ТекСтрока) Экспорт
		
	Если ТекСтрока.Выбран Тогда
		ДобавитьВыбранныйТип(ТекСтрока);
	КонецЕсли;

	Если ВыбранныеТипы.Количество()=0 Тогда
		ДобавитьВыбранныйТип("Строка");
	КонецЕсли;
	
	УстановитьВыбранныеТипыВДереве(ДеревоТипов,ВыбранныеТипы);
КонецПроцедуры

&НаСервере
Процедура ДобавитьТипыВМассивПоКоллекцииМетаданных(МассивТипов, Коллекция, ПрефиксТипа)
	Для Каждого ОбъектМД ИЗ Коллекция Цикл
		МассивТипов.Добавить(Тип(ПрефиксТипа+ОбъектМД.Имя));
	КонецЦикла;
КонецПроцедуры

&НаСервере
Функция МассивВыбранныхТипов()
	МассивТипов=Новый Массив;
	
	Для Каждого ЭлементТипа Из ВыбранныеТипы Цикл
		СтрокаТипа=ЭлементТипа.Значение;
		
		Если НРег(СтрокаТипа)="любаяссылка" Тогда
			ДобавитьТипыВМассивПоКоллекцииМетаданных(МассивТипов, Метаданные.Справочники,"СправочникСсылка.");
			ДобавитьТипыВМассивПоКоллекцииМетаданных(МассивТипов, Метаданные.Документы,"ДокументСсылка.");
			ДобавитьТипыВМассивПоКоллекцииМетаданных(МассивТипов, Метаданные.ПланыВидовХарактеристик,"ПланВидовХарактеристикСсылка.");
			ДобавитьТипыВМассивПоКоллекцииМетаданных(МассивТипов, Метаданные.ПланыСчетов,"ПланСчетовСсылка.");
			ДобавитьТипыВМассивПоКоллекцииМетаданных(МассивТипов, Метаданные.ПланыВидовРасчета,"ПланВидовРасчетаСсылка.");
			ДобавитьТипыВМассивПоКоллекцииМетаданных(МассивТипов, Метаданные.ПланыОбмена,"ПланОбменаСсылка.");
			ДобавитьТипыВМассивПоКоллекцииМетаданных(МассивТипов, Метаданные.Перечисления,"ПеречислениеСсылка.");
			ДобавитьТипыВМассивПоКоллекцииМетаданных(МассивТипов, Метаданные.БизнесПроцессы,"БизнесПроцессСсылка.");
			ДобавитьТипыВМассивПоКоллекцииМетаданных(МассивТипов, Метаданные.Задачи,"ЗадачаСсылка.");
		ИначеЕсли СтрНайти(НРег(СтрокаТипа),"ссылка")>0 И СтрНайти(СтрокаТипа,".")=0 Тогда
			Если НРег(СтрокаТипа)="справочникссылка" Тогда
				ДобавитьТипыВМассивПоКоллекцииМетаданных(МассивТипов, Метаданные.Справочники,"СправочникСсылка.");
			ИначеЕсли НРег(СтрокаТипа)="документссылка" Тогда	
				ДобавитьТипыВМассивПоКоллекцииМетаданных(МассивТипов, Метаданные.Документы,"ДокументСсылка.");
			ИначеЕсли НРег(СтрокаТипа)="планвидовхарактеристикссылка" Тогда	
				ДобавитьТипыВМассивПоКоллекцииМетаданных(МассивТипов, Метаданные.ПланыВидовХарактеристик,"ПланВидовХарактеристикСсылка.");
			ИначеЕсли НРег(СтрокаТипа)="плансчетовссылка" Тогда	
				ДобавитьТипыВМассивПоКоллекцииМетаданных(МассивТипов, Метаданные.ПланыСчетов,"ПланСчетовСсылка.");
			ИначеЕсли НРег(СтрокаТипа)="планвидоврасчетассылка" Тогда	
				ДобавитьТипыВМассивПоКоллекцииМетаданных(МассивТипов, Метаданные.ПланыВидовРасчета,"ПланВидовРасчетаСсылка.");
			ИначеЕсли НРег(СтрокаТипа)="планобменассылка" Тогда	
				ДобавитьТипыВМассивПоКоллекцииМетаданных(МассивТипов, Метаданные.ПланыОбмена,"ПланОбменаСсылка.");
			ИначеЕсли НРег(СтрокаТипа)="перечислениессылка" Тогда	
				ДобавитьТипыВМассивПоКоллекцииМетаданных(МассивТипов, Метаданные.Перечисления,"ПеречислениеСсылка.");
			ИначеЕсли НРег(СтрокаТипа)="бизнеспроцессссылка" Тогда	
				ДобавитьТипыВМассивПоКоллекцииМетаданных(МассивТипов, Метаданные.БизнесПроцессы,"БизнесПроцессСсылка.");
			ИначеЕсли НРег(СтрокаТипа)="задачассылка" Тогда	
				ДобавитьТипыВМассивПоКоллекцииМетаданных(МассивТипов, Метаданные.Задачи,"ЗадачаСсылка.");
			КонецЕсли;
		ИначеЕсли ЭлементТипа.Пометка Тогда
			МассивИмени=СтрРазделить(СтрокаТипа,".");
			Если МассивИмени.Количество()<>2 Тогда
				Продолжить;
			КонецЕсли;
			ИмяОбъекта=МассивИмени[1];
			Если СтрНайти(НРег(СтрокаТипа),"характеристика")>0 Тогда
				ОбъектМД=Метаданные.ПланыВидовХарактеристик[ИмяОбъекта];
			ИначеЕсли СтрНайти(НРег(СтрокаТипа),"определяемыйтип")>0 Тогда
				ОбъектМД=Метаданные.ОпределяемыеТипы[ИмяОбъекта];
			Иначе
				Продолжить;
			КонецЕсли;
			ОписаниеТипа=ОбъектМД.Тип;
			
			Для Каждого ТекТип ИЗ ОписаниеТипа.Типы() Цикл
				МассивТипов.Добавить(ТекТип);
			КонецЦикла;
			
		Иначе
			МассивТипов.Добавить(ЭлементТипа.Значение);
		КонецЕсли;
	КонецЦикла;
	
	Возврат МассивТипов;
	
КонецФункции

&НаСервере
Процедура ЗаполнитьДанныеКвалификаторовПоПервоначальномуТипуДанных()
	ДлинаЧисла=НачальныйТипДанных.КвалификаторыЧисла.Разрядность;
	ТочностьЧисла=НачальныйТипДанных.КвалификаторыЧисла.РазрядностьДробнойЧасти;
	НеотрицательноеЧисло= НачальныйТипДанных.КвалификаторыЧисла.ДопустимыйЗнак=ДопустимыйЗнак.Неотрицательный;
	
	ДлинаСтроки=НачальныйТипДанных.КвалификаторыСтроки.Длина;
	НеограниченнаяДлинаСтроки=Не ЗначениеЗаполнено(ДлинаСтроки);
	ДопустамаяДлинаСтрокиФиксированная=НачальныйТипДанных.КвалификаторыСтроки.ДопустимаяДлина=ДопустимаяДлина.Фиксированная;

	Если НачальныйТипДанных.КвалификаторыДаты.ЧастиДаты=ЧастиДаты.Время Тогда
		СоставДаты= 1;
	ИначеЕсли НачальныйТипДанных.КвалификаторыДаты.ЧастиДаты=ЧастиДаты.ДатаВремя Тогда
		СоставДаты=2;
	КонецЕсли;
КонецПроцедуры

#КонецОбласти